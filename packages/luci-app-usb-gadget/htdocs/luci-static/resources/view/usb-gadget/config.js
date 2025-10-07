'use strict';
'require view';
'require form';
'require uci';
'require ui';
'require fs';

return view.extend({
    load: function() {
        return Promise.all([
            uci.load('usbgadget'),
            L.resolveDefault(fs.list('/sys/class/udc'), [])
        ]);
    },

    render: function(data) {
        var udc_devices = data[1];
        var m, s, o;

        m = new form.Map('usbgadget', 
            _('USB Gadget Configuration'),
            _('Configure USB gadget functions to make OpenWrt appear as various USB devices when connected to a host computer.'));

        // Device Configuration Section
        s = m.section(form.TypedSection, 'device', _('Device Settings'));
        s.anonymous = true;
        s.addremove = false;

        o = s.option(form.Flag, 'enabled', _('Enable USB Gadget'),
            _('Enable USB gadget mode. Disable to use USB port in host mode (for USB storage, etc.)'));
        o.rmempty = false;
        o.default = '1';

        o = s.option(form.Value, 'gadget_name', _('Gadget Name'),
            _('Internal gadget identifier. Can be any string.'));
        o.placeholder = 'g1';
        o.default = 'g1';

        o = s.option(form.Value, 'manufacturer', _('Manufacturer String'),
            _('USB manufacturer string shown to the host computer'));
        o.placeholder = 'OpenWrt';
        o.default = 'OpenWrt';

        o = s.option(form.Value, 'product', _('Product String'),
            _('USB product string shown to the host computer'));
        o.placeholder = 'USB Gadget';
        o.default = 'USB Gadget';

        o = s.option(form.Value, 'vendor_id', _('Vendor ID'),
            _('USB Vendor ID in hexadecimal format (0x1d6b = Linux Foundation)'));
        o.placeholder = '0x1d6b';
        o.default = '0x1d6b';
        o.validate = function(section_id, value) {
            if (!/^0x[0-9a-fA-F]{4}$/.test(value))
                return _('Must be a 4-digit hexadecimal number (e.g., 0x1d6b)');
            return true;
        };

        o = s.option(form.Value, 'product_id', _('Product ID'),
            _('USB Product ID in hexadecimal format'));
        o.placeholder = '0x0104';
        o.default = '0x0104';
        o.validate = function(section_id, value) {
            if (!/^0x[0-9a-fA-F]{4}$/.test(value))
                return _('Must be a 4-digit hexadecimal number (e.g., 0x0104)');
            return true;
        };

        o = s.option(form.Value, 'device_version', _('Device Version'),
            _('USB device version in BCD format'));
        o.placeholder = '0x0100';
        o.default = '0x0100';

        if (udc_devices.length > 0) {
            o = s.option(form.ListValue, 'udc_device', _('UDC Device'),
                _('USB Device Controller. Leave empty for auto-detection.'));
            o.value('', _('Auto-detect'));
            udc_devices.forEach(function(dev) {
                o.value(dev.name, dev.name);
            });
        }

        // USB Functions Section
        s = m.section(form.TypedSection, 'function', _('USB Functions'),
            _('Enable one or more USB functions. Only one network function (RNDIS/ECM/NCM) should be enabled at a time.'));
        s.anonymous = false;
        s.addremove = false;

        s.tab('network', _('Network Functions'));
        s.tab('serial', _('Serial Console'));
        s.tab('storage', _('Mass Storage'));

        // RNDIS
        o = s.taboption('network', form.Flag, 'enabled', _('Enable'));
        o.modalonly = false;
        o.depends('.name', 'rndis');
        o.rmempty = false;

        o = s.taboption('network', form.DummyValue, '_rndis_desc', _('Description'));
        o.depends('.name', 'rndis');
        o.rawhtml = true;
        o.cfgvalue = function() {
            return _('RNDIS - Windows compatible USB ethernet (plug-and-play on all Windows versions)');
        };

        // ECM
        o = s.taboption('network', form.Flag, 'enabled', _('Enable'));
        o.depends('.name', 'ecm');
        o.rmempty = false;

        o = s.taboption('network', form.DummyValue, '_ecm_desc', _('Description'));
        o.depends('.name', 'ecm');
        o.rawhtml = true;
        o.cfgvalue = function() {
            return _('ECM - CDC Ethernet for macOS (≤10.14) and Linux. Do not enable with NCM.');
        };

        // NCM
        o = s.taboption('network', form.Flag, 'enabled', _('Enable'));
        o.depends('.name', 'ncm');
        o.rmempty = false;

        o = s.taboption('network', form.DummyValue, '_ncm_desc', _('Description'));
        o.depends('.name', 'ncm');
        o.rawhtml = true;
        o.cfgvalue = function() {
            return _('NCM - Modern high-performance USB ethernet for Windows 11+, macOS ≥10.15, Linux. Best performance.');
        };

        // ACM Serial
        o = s.taboption('serial', form.Flag, 'enabled', _('Enable Serial Console'));
        o.depends('.name', 'acm');
        o.rmempty = false;

        o = s.taboption('serial', form.Flag, 'shell', _('Enable Login Shell'),
            _('Provide login shell on serial console. Disable for raw TTY mode.'));
        o.depends('.name', 'acm');
        o.default = '1';

        o = s.taboption('serial', form.DummyValue, '_acm_info', _('Connection Info'));
        o.depends('.name', 'acm');
        o.rawhtml = true;
        o.cfgvalue = function() {
            return _('Access via /dev/ttyACM0 on Linux/macOS or COMx on Windows. Use: screen /dev/ttyACM0 115200');
        };

        // Mass Storage
        o = s.taboption('storage', form.Flag, 'enabled', _('Enable Mass Storage'));
        o.depends('.name', 'ums');
        o.rmempty = false;

        o = s.taboption('storage', form.Value, 'image_path', _('Image File Path'),
            _('Path to storage image file. Created automatically if it doesn\'t exist.'));
        o.depends('.name', 'ums');
        o.default = '/var/lib/usb-gadget/storage.img';
        o.rmempty = false;

        o = s.taboption('storage', form.Value, 'image_size', _('Image Size'),
            _('Size of image file when created (e.g., 512M, 1G, 2G)'));
        o.depends('.name', 'ums');
        o.default = '512M';
        o.placeholder = '512M';

        o = s.taboption('storage', form.Flag, 'readonly', _('Read-Only Mode'),
            _('Mount storage as read-only on the host'));
        o.depends('.name', 'ums');
        o.default = '0';

        return m.render();
    }
});
