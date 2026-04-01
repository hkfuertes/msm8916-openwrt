#!/usr/bin/env python3
"""
xqcn_restore.py — Restore XQCN backup to Qualcomm MSM8916 modem via DIAG port.

Usage:
    # Backup current modem NV items first:
    python3 xqcn_restore.py --port /dev/ttyUSB0 --backup backup_uf02.bin

    # Restore XQCN (skipping IMEI NV 550):
    python3 xqcn_restore.py --port /dev/ttyUSB0 --restore uz801.xqcn

    # Restore XQCN and then write a specific IMEI:
    python3 xqcn_restore.py --port /dev/ttyUSB0 --restore uz801.xqcn --imei 123456789012345

    # Just read a single NV item:
    python3 xqcn_restore.py --port /dev/ttyUSB0 --read-nv 550

    # Dry-run (parse XQCN and show what would be written):
    python3 xqcn_restore.py --restore uz801.xqcn --dry-run
"""

from __future__ import annotations

import argparse
import re
import struct
import sys
import time

# ============================================================
# HDLC / CRC-16 CCITT
# ============================================================

CRC_TABLE = []
for _i in range(256):
    _crc = _i
    for _ in range(8):
        _crc = (_crc >> 1) ^ 0x8408 if _crc & 1 else _crc >> 1
    CRC_TABLE.append(_crc)


def crc16(data: bytes) -> int:
    crc = 0xFFFF
    for b in data:
        crc = (crc >> 8) ^ CRC_TABLE[(crc ^ b) & 0xFF]
    return crc ^ 0xFFFF


def hdlc_encode(payload: bytes) -> bytes:
    crc = crc16(payload)
    raw = payload + struct.pack('<H', crc)
    out = bytearray()
    for b in raw:
        if b == 0x7E or b == 0x7D:
            out.append(0x7D)
            out.append(b ^ 0x20)
        else:
            out.append(b)
    out.append(0x7E)
    return bytes(out)


def hdlc_decode(frame: bytes) -> bytes:
    """Remove HDLC framing, un-escape, verify CRC. Returns payload without CRC."""
    # Strip trailing 0x7E(s)
    while frame and frame[-1] == 0x7E:
        frame = frame[:-1]
    # Strip leading 0x7E(s)
    while frame and frame[0] == 0x7E:
        frame = frame[1:]
    # Un-escape
    out = bytearray()
    i = 0
    while i < len(frame):
        if frame[i] == 0x7D and i + 1 < len(frame):
            out.append(frame[i + 1] ^ 0x20)
            i += 2
        else:
            out.append(frame[i])
            i += 1
    # Verify CRC
    if len(out) < 3:
        raise ValueError(f"Frame too short: {len(out)} bytes")
    payload = bytes(out[:-2])
    expected_crc = struct.unpack('<H', out[-2:])[0]
    actual_crc = crc16(payload)
    if expected_crc != actual_crc:
        raise ValueError(f"CRC mismatch: expected 0x{expected_crc:04X}, got 0x{actual_crc:04X}")
    return payload


# ============================================================
# DIAG serial communication
# ============================================================

class DiagPort:
    """Low-level DIAG port communication."""

    def __init__(self, port_path: str, timeout: float = 2.0):
        import serial
        self.ser = serial.Serial(port_path, baudrate=115200, timeout=timeout)
        self.ser.reset_input_buffer()

    def send_recv(self, payload: bytes, retries: int = 2) -> bytes:
        frame = hdlc_encode(payload)
        for attempt in range(retries + 1):
            self.ser.reset_input_buffer()
            self.ser.write(frame)
            self.ser.flush()
            resp = self._read_frame()
            if resp is not None:
                return resp
            if attempt < retries:
                time.sleep(0.1)
        raise TimeoutError(f"No response after {retries + 1} attempts (cmd=0x{payload[0]:02X})")

    def _read_frame(self) -> bytes | None:
        """Read until 0x7E delimiter."""
        buf = bytearray()
        deadline = time.time() + self.ser.timeout
        while time.time() < deadline:
            chunk = self.ser.read(max(1, self.ser.in_waiting))
            if not chunk:
                continue
            buf.extend(chunk)
            if 0x7E in buf[1:]:  # at least 1 byte before delimiter
                try:
                    return hdlc_decode(bytes(buf))
                except ValueError:
                    return None
        return None

    def close(self):
        self.ser.close()


# ============================================================
# DIAG commands
# ============================================================

CMD_NV_READ = 0x26
CMD_NV_WRITE = 0x27
CMD_SUBSYS = 0x4B
SUBSYS_EFS2 = 0x13

# EFS2 sub-commands
EFS2_OPEN = 0x01
EFS2_CLOSE = 0x02
EFS2_WRITE = 0x03

# EFS open flags (POSIX-like)
O_CREAT = 0x0100
O_TRUNC = 0x0200
O_WRONLY = 0x0001


def nv_read(diag: DiagPort, nv_id: int) -> tuple[int, bytes]:
    """Read NV item. Returns (status, 128-byte data)."""
    payload = struct.pack('<BH', CMD_NV_READ, nv_id) + b'\x00' * 128
    resp = diag.send_recv(payload)
    if resp[0] != CMD_NV_READ:
        raise RuntimeError(f"Unexpected response cmd: 0x{resp[0]:02X}")
    resp_id = struct.unpack('<H', resp[1:3])[0]
    # Data is 128 bytes starting at offset 3
    data = resp[3:131] if len(resp) >= 131 else resp[3:]
    # Status: 0 = success. Some firmwares put status at different positions.
    # Typically if the response is the right length and cmd matches, it succeeded.
    status = 0 if len(resp) >= 131 else -1
    return status, data.ljust(128, b'\x00')


def nv_write(diag: DiagPort, nv_id: int, data: bytes) -> int:
    """Write NV item (128 bytes). Returns status (0=ok)."""
    data = data[:128].ljust(128, b'\x00')
    payload = struct.pack('<BH', CMD_NV_WRITE, nv_id) + data
    resp = diag.send_recv(payload)
    if resp[0] == CMD_NV_WRITE:
        return 0
    elif resp[0] == 0x14:  # BAD_CMD / not supported
        return -1
    return resp[0]


def efs_write_file(diag: DiagPort, path: str, data: bytes) -> bool:
    """Write a file to EFS2 via DIAG subsystem dispatch."""
    # Open file
    flags = O_CREAT | O_TRUNC | O_WRONLY
    mode = 0o0644
    open_payload = struct.pack('<BBHIH', CMD_SUBSYS, SUBSYS_EFS2, EFS2_OPEN,
                               flags, mode) + path.encode('ascii') + b'\x00'
    resp = diag.send_recv(open_payload)
    if resp[0] != CMD_SUBSYS or len(resp) < 8:
        print(f"    EFS open failed for {path}: resp={resp[:8].hex()}")
        return False
    fd = struct.unpack('<i', resp[4:8])[0]
    if fd < 0:
        errno_val = struct.unpack('<i', resp[8:12])[0] if len(resp) >= 12 else -1
        print(f"    EFS open error for {path}: fd={fd}, errno={errno_val}")
        return False

    # Write data in chunks (max ~512 bytes per write to be safe)
    CHUNK = 512
    offset = 0
    while offset < len(data):
        chunk = data[offset:offset + CHUNK]
        write_payload = struct.pack('<BBHIIIH', CMD_SUBSYS, SUBSYS_EFS2, EFS2_WRITE,
                                    fd, offset, len(chunk), 0) + chunk
        resp = diag.send_recv(write_payload)
        if resp[0] != CMD_SUBSYS:
            print(f"    EFS write failed for {path} at offset {offset}")
            break
        offset += len(chunk)

    # Close file
    close_payload = struct.pack('<BBHI', CMD_SUBSYS, SUBSYS_EFS2, EFS2_CLOSE, fd)
    diag.send_recv(close_payload)
    return offset >= len(data)


# ============================================================
# XQCN parser
# ============================================================

def parse_xqcn(filepath: str) -> dict:
    """Parse an XQCN file. Returns dict with nv_items, efs_backup, nv_efs_items."""
    with open(filepath, 'r', encoding='windows-1252') as f:
        content = f.read()

    result = {
        'nv_items': [],       # (nv_id, 128-byte data) from NV_ITEM_ARRAY
        'efs_backup': [],     # (path, data) from EFS_Backup
        'prov_items': [],     # (path, data) from Provisioning_Item_Files
        'nv_efs_items': [],   # (path, data) from NV_Items
    }

    # --- NV_ITEM_ARRAY (numbered NV items, 136-byte records) ---
    match = re.search(r"NV_ITEM_ARRAY'\s*Value='([^']+)'", content)
    if match:
        data = bytes.fromhex(match.group(1).replace(' ', ''))
        record_size = 136
        for off in range(0, len(data), record_size):
            rec = data[off:off + record_size]
            if len(rec) < record_size:
                break
            nv_id = struct.unpack('<H', rec[4:6])[0]
            nv_data = rec[6:134]  # 128 bytes
            if nv_id > 0 and any(nv_data):  # skip empty/zero entries
                result['nv_items'].append((nv_id, nv_data))

    # --- EFS sections ---
    all_dirs = list(re.finditer(
        r"<Storage Name='EFS_Dir'>(.*?)</Storage>", content, re.DOTALL))
    all_datas = list(re.finditer(
        r"<Storage Name='EFS_Data'>(.*?)</Storage>", content, re.DOTALL))

    stream_re = re.compile(
        r"Stream\s+Length='\d+'\s+Name='([^']+)'\s+Value='([^']*)'")

    for idx in range(min(len(all_dirs), len(all_datas))):
        dir_entries = stream_re.findall(all_dirs[idx].group(1))
        data_entries = dict(stream_re.findall(all_datas[idx].group(1)))

        for name, val in dir_entries:
            raw_dir = bytes.fromhex(val.replace(' ', ''))
            # Extract path: EFS_Backup has 8-byte header, NV_Items has raw path
            slash_pos = raw_dir.find(b'/')
            if slash_pos < 0:
                # No slash - might be relative path
                path = raw_dir.decode('ascii', errors='replace').rstrip('\x00')
            else:
                path = raw_dir[slash_pos:].decode('ascii', errors='replace').rstrip('\x00')

            if not path:
                continue

            if name in data_entries:
                file_data = bytes.fromhex(data_entries[name].replace(' ', ''))
            else:
                file_data = None

            # Classify by section index based on parent
            if idx == 0:
                result['efs_backup'].append((path, file_data))
            elif idx == 1:
                result['prov_items'].append((path, file_data))
            else:
                result['nv_efs_items'].append((path, file_data))

    return result


# ============================================================
# IMEI encoding/decoding
# ============================================================

def encode_imei(imei_str: str) -> bytes:
    """Encode IMEI string (15 digits) to NV 550 format.

    NV 550 payload layout (from the XQCN):
      bytes 0-1: subscription index (0x00 0x00)
      byte 2:    0x08 (IMEI length = 8 bytes following)
      bytes 3-10: BCD-encoded IMEI (swapped nibbles)
    """
    if len(imei_str) != 15 or not imei_str.isdigit():
        raise ValueError(f"IMEI must be exactly 15 digits, got: {imei_str}")
    digits = [int(d) for d in imei_str]
    encoded = bytearray(11)  # 2 (sub) + 1 (len) + 8 (BCD)
    encoded[0] = 0x00  # subscription index low
    encoded[1] = 0x00  # subscription index high
    encoded[2] = 0x08  # length
    # First BCD byte: type nibble (0xA) | first digit
    encoded[3] = 0x0A | (digits[0] << 4)
    for i in range(1, 15, 2):
        byte_idx = 3 + 1 + (i - 1) // 2
        if i + 1 < 15:
            encoded[byte_idx] = digits[i] | (digits[i + 1] << 4)
        else:
            encoded[byte_idx] = digits[i] | 0xF0
    return bytes(encoded)


def decode_imei(data: bytes) -> str:
    """Decode IMEI from NV 550 format (with 2-byte subscription prefix)."""
    # Skip 2-byte subscription index
    if len(data) >= 11 and data[2] == 0x08:
        d = data[2:]  # skip sub index, now d[0]=0x08
    elif len(data) >= 9 and data[0] == 0x08:
        d = data
    else:
        return "(unknown format)"
    digits = []
    digits.append((d[1] >> 4) & 0x0F)
    for i in range(2, 9):
        digits.append(d[i] & 0x0F)
        d2 = (d[i] >> 4) & 0x0F
        if d2 != 0x0F:
            digits.append(d2)
    return ''.join(str(d) for d in digits[:15])


# ============================================================
# Main operations
# ============================================================

NV_IMEI = 550
SKIP_NV_IDS = {NV_IMEI}  # NV items to skip during restore (IMEI by default)


def do_dry_run(xqcn_path: str):
    """Parse XQCN and show contents without writing."""
    print(f"Parsing {xqcn_path}...")
    xqcn = parse_xqcn(xqcn_path)

    print(f"\n=== NV Items (numbered): {len(xqcn['nv_items'])} ===")
    for nv_id, data in xqcn['nv_items'][:20]:
        nonzero = sum(1 for b in data if b)
        print(f"  NV {nv_id:5d} (0x{nv_id:04X})  nonzero_bytes={nonzero}")
    if len(xqcn['nv_items']) > 20:
        print(f"  ... and {len(xqcn['nv_items']) - 20} more")

    for section, label in [('efs_backup', 'EFS Backup'),
                           ('prov_items', 'Provisioning Items'),
                           ('nv_efs_items', 'NV/EFS Items')]:
        items = xqcn[section]
        with_data = [(p, d) for p, d in items if d is not None]
        print(f"\n=== {label}: {len(items)} paths, {len(with_data)} with data ===")
        for path, data in with_data[:15]:
            size = len(data) if data else 0
            print(f"  {path}  ({size} bytes)")
        if len(with_data) > 15:
            print(f"  ... and {len(with_data) - 15} more")

    # Check for IMEI
    for nv_id, data in xqcn['nv_items']:
        if nv_id == NV_IMEI:
            print(f"\n⚠  XQCN contains IMEI (NV 550): {decode_imei(data)}")
            print("   This will be SKIPPED during restore. Use --imei to set yours.")


def do_backup(diag: DiagPort, output_path: str):
    """Backup all readable NV items to a binary file."""
    print("Backing up NV items...")
    items = []
    errors = 0
    for nv_id in range(0, 7000):
        try:
            status, data = nv_read(diag, nv_id)
            if status == 0 and any(data):
                items.append((nv_id, data))
                if len(items) % 100 == 0:
                    print(f"  ... {len(items)} items read (scanning NV {nv_id})")
        except (TimeoutError, ValueError):
            errors += 1
            continue

    with open(output_path, 'wb') as f:
        for nv_id, data in items:
            f.write(struct.pack('<H', nv_id))
            f.write(data)

    print(f"Backed up {len(items)} NV items to {output_path} ({errors} errors skipped)")


def do_restore(diag: DiagPort, xqcn_path: str, imei: str | None = None):
    """Restore XQCN to modem via DIAG port."""
    print(f"Parsing {xqcn_path}...")
    xqcn = parse_xqcn(xqcn_path)

    # --- Phase 1: Backup current IMEI ---
    print("\n[1/4] Reading current IMEI (NV 550)...")
    try:
        status, imei_data = nv_read(diag, NV_IMEI)
        current_imei = decode_imei(imei_data)
        print(f"  Current IMEI: {current_imei}")
    except Exception as e:
        current_imei = None
        print(f"  Could not read IMEI: {e}")

    # --- Phase 2: Write NV numbered items ---
    nv_items = [(nv_id, data) for nv_id, data in xqcn['nv_items']
                if nv_id not in SKIP_NV_IDS]
    print(f"\n[2/4] Writing {len(nv_items)} NV items (skipping NV {', '.join(str(i) for i in SKIP_NV_IDS)})...")

    nv_ok = 0
    nv_fail = 0
    for i, (nv_id, data) in enumerate(nv_items):
        try:
            status = nv_write(diag, nv_id, data)
            if status == 0:
                nv_ok += 1
            else:
                nv_fail += 1
                if nv_fail <= 10:
                    print(f"  NV {nv_id}: write returned status {status}")
        except (TimeoutError, ValueError) as e:
            nv_fail += 1
            if nv_fail <= 10:
                print(f"  NV {nv_id}: {e}")
        if (i + 1) % 100 == 0:
            print(f"  ... {i + 1}/{len(nv_items)} ({nv_ok} ok, {nv_fail} failed)")
        time.sleep(0.02)  # small delay to not overwhelm the modem

    print(f"  NV items: {nv_ok} ok, {nv_fail} failed")

    # --- Phase 3: Write EFS files ---
    efs_sections = [
        ('efs_backup', 'EFS Backup files'),
        ('prov_items', 'Provisioning items'),
        ('nv_efs_items', 'NV/EFS items'),
    ]

    total_efs_ok = 0
    total_efs_fail = 0
    section_num = 3

    for section_key, section_label in efs_sections:
        items = [(p, d) for p, d in xqcn[section_key] if d is not None]
        if not items:
            continue
        print(f"\n[{section_num}/4] Writing {len(items)} {section_label}...")
        section_num += 1
        efs_ok = 0
        efs_fail = 0
        for path, data in items:
            try:
                if efs_write_file(diag, path, data):
                    efs_ok += 1
                else:
                    efs_fail += 1
            except (TimeoutError, ValueError) as e:
                efs_fail += 1
                if efs_fail <= 5:
                    print(f"    {path}: {e}")
            time.sleep(0.02)

        print(f"  {section_label}: {efs_ok} ok, {efs_fail} failed")
        total_efs_ok += efs_ok
        total_efs_fail += efs_fail

    # --- Phase 4: Restore IMEI ---
    target_imei = imei or current_imei
    if target_imei:
        print(f"\n[IMEI] Writing IMEI: {target_imei}")
        try:
            imei_bytes = encode_imei(target_imei)
            status = nv_write(diag, NV_IMEI, imei_bytes + b'\x00' * (128 - len(imei_bytes)))
            if status == 0:
                print(f"  IMEI written successfully")
            else:
                print(f"  IMEI write failed: status={status}")
        except Exception as e:
            print(f"  IMEI write error: {e}")
    else:
        print("\n[IMEI] No IMEI to write (could not read current, none specified with --imei)")

    # --- Summary ---
    print(f"\n{'='*50}")
    print(f"RESTORE COMPLETE")
    print(f"  NV items:  {nv_ok} ok / {nv_fail} failed")
    print(f"  EFS files: {total_efs_ok} ok / {total_efs_fail} failed")
    if target_imei:
        print(f"  IMEI:      {target_imei}")
    print(f"\nReboot the modem for changes to take effect.")
    print(f"  (adb shell reboot)")


def do_read_nv(diag: DiagPort, nv_id: int):
    """Read and display a single NV item."""
    print(f"Reading NV {nv_id} (0x{nv_id:04X})...")
    status, data = nv_read(diag, nv_id)
    print(f"  Status: {status}")
    # Show first N non-zero bytes
    nonzero_end = 128
    while nonzero_end > 0 and data[nonzero_end - 1] == 0:
        nonzero_end -= 1
    if nonzero_end == 0:
        print("  Data: (all zeros)")
    else:
        print(f"  Data ({nonzero_end} bytes): {data[:nonzero_end].hex(' ')}")
    if nv_id == NV_IMEI:
        print(f"  IMEI: {decode_imei(data)}")


# ============================================================
# CLI
# ============================================================

def main():
    parser = argparse.ArgumentParser(
        description='Restore XQCN backup to Qualcomm modem via DIAG port',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument('--port', '-p', help='DIAG serial port (e.g. /dev/ttyUSB0)')
    parser.add_argument('--restore', '-r', metavar='XQCN',
                        help='XQCN file to restore')
    parser.add_argument('--backup', '-b', metavar='FILE',
                        help='Backup current NV items to binary file')
    parser.add_argument('--imei', help='IMEI to write after restore (15 digits)')
    parser.add_argument('--read-nv', type=int, metavar='ID',
                        help='Read a single NV item')
    parser.add_argument('--dry-run', action='store_true',
                        help='Parse XQCN and show contents without writing')
    parser.add_argument('--timeout', type=float, default=2.0,
                        help='Serial port timeout in seconds (default: 2.0)')

    args = parser.parse_args()

    if not any([args.restore, args.backup, args.read_nv, args.dry_run]):
        parser.print_help()
        sys.exit(1)

    # Dry run doesn't need port
    if args.dry_run and args.restore:
        do_dry_run(args.restore)
        return

    if not args.port:
        print("Error: --port is required for this operation", file=sys.stderr)
        sys.exit(1)

    try:
        import serial  # noqa: F401
    except ImportError:
        print("Error: pyserial is required. Install with: pip install pyserial", file=sys.stderr)
        sys.exit(1)

    diag = DiagPort(args.port, timeout=args.timeout)

    try:
        if args.backup:
            do_backup(diag, args.backup)
        if args.read_nv is not None:
            do_read_nv(diag, args.read_nv)
        if args.restore:
            do_restore(diag, args.restore, args.imei)
    finally:
        diag.close()


if __name__ == '__main__':
    main()
