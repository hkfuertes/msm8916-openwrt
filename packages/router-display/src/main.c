#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <getopt.h>
#include <unistd.h>
#include <ctype.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include "qrcodegen.h"

#define WIDTH 128
#define HEIGHT 128
#define RGB565(r,g,b) (((r & 0xF8) << 8) | ((g & 0xFC) << 3) | ((b & 0xF8) >> 3))

#define COLOR_WHITE RGB565(255, 255, 255)
#define COLOR_BLACK RGB565(0, 0, 0)

#define QR_SIZE 108
#define QR_TOP_MARGIN 6
#define TEXT_HEIGHT 13
#define MIN_MODULE_SIZE 3  // Minimum pixels per QR module for readability

typedef struct {
    uint16_t data[WIDTH * HEIGHT];
} Framebuffer;

typedef struct {
    int battery;
    int charging;        // NEW: charging flag
    char operator[32];
    char network_type[8];
    char ssid[64];
    char password[64];
    char hostname[32];
    int show_qr;
    int uppercase;
} DisplayConfig;

void fb_init(Framebuffer *fb) {
    memset(fb->data, 0, sizeof(fb->data));
}

void fb_put_pixel(Framebuffer *fb, int x, int y, uint16_t color) {
    if (x >= 0 && x < WIDTH && y >= 0 && y < HEIGHT) {
        fb->data[y * WIDTH + x] = color;
    }
}

void fb_blend_pixel(Framebuffer *fb, int x, int y, unsigned char gray) {
    if (x < 0 || x >= WIDTH || y < 0 || y >= HEIGHT) return;
    if (gray == 0) return;
    
    uint16_t bg_color = fb->data[y * WIDTH + x];
    
    uint8_t bg_r = (bg_color >> 11) << 3;
    uint8_t bg_g = ((bg_color >> 5) & 0x3F) << 2;
    uint8_t bg_b = (bg_color & 0x1F) << 3;
    
    float alpha = gray / 255.0f;
    uint8_t r = (uint8_t)(255 * alpha + bg_r * (1.0f - alpha));
    uint8_t g = (uint8_t)(255 * alpha + bg_g * (1.0f - alpha));
    uint8_t b = (uint8_t)(255 * alpha + bg_b * (1.0f - alpha));
    
    fb->data[y * WIDTH + x] = RGB565(r, g, b);
}

void fb_draw_rect(Framebuffer *fb, int x, int y, int w, int h, uint16_t color) {
    for (int j = 0; j < h; j++) {
        for (int i = 0; i < w; i++) {
            fb_put_pixel(fb, x + i, y + j, color);
        }
    }
}

void fb_draw_text(Framebuffer *fb, FT_Face face, const char *text, int x, int y, int size) {
    int pen_x = x;
    
    for (const char *p = text; *p; p++) {
        FT_Set_Pixel_Sizes(face, 0, size);
        
        if (FT_Load_Char(face, *p, FT_LOAD_RENDER | FT_LOAD_TARGET_NORMAL)) {
            continue;
        }
        
        FT_GlyphSlot slot = face->glyph;
        FT_Bitmap bitmap = slot->bitmap;
        
        for (unsigned int row = 0; row < bitmap.rows; row++) {
            for (unsigned int col = 0; col < bitmap.width; col++) {
                int px = pen_x + slot->bitmap_left + col;
                int py = y - slot->bitmap_top + row;
                
                unsigned char gray = bitmap.buffer[row * bitmap.pitch + col];
                
                if (gray > 0) {
                    fb_blend_pixel(fb, px, py, gray);
                }
            }
        }
        
        pen_x += slot->advance.x >> 6;
    }
}

int fb_get_text_width(FT_Face face, const char *text, int size) {
    int width = 0;
    FT_Set_Pixel_Sizes(face, 0, size);
    
    for (const char *p = text; *p; p++) {
        if (FT_Load_Char(face, *p, FT_LOAD_RENDER)) {
            continue;
        }
        width += face->glyph->advance.x >> 6;
    }
    
    return width;
}

int fb_draw_qr(Framebuffer *fb, const char *text, int x, int y, int size) {
    uint8_t qr_data[qrcodegen_BUFFER_LEN_MAX];
    uint8_t temp_buffer[qrcodegen_BUFFER_LEN_MAX];
    
    bool ok = qrcodegen_encodeText(text, temp_buffer, qr_data,
                                   qrcodegen_Ecc_LOW, 
                                   qrcodegen_VERSION_MIN,
                                   qrcodegen_VERSION_MAX,
                                   qrcodegen_Mask_AUTO, true);
    
    if (!ok) {
        fprintf(stderr, "QR generation failed\n");
        return 0;
    }
    
    int qr_modules = qrcodegen_getSize(qr_data);
    int module_size = size / qr_modules;
    
    // Check if QR modules are too small (minimum pixels per module)
    if (module_size < MIN_MODULE_SIZE) {
        fprintf(stderr, "QR too large for display area (needs %d modules, only fits %dpx modules)\n", 
                qr_modules, module_size);
        return 0;  // Don't draw, QR would be unreadable
    }
    
    // Calculate actual QR size and center horizontally, align top vertically
    int actual_qr_size = qr_modules * module_size;
    int offset_x = (size - actual_qr_size) / 2;  // Center horizontally
    int offset_y = 0;                             // Top aligned
    
    for (int row = 0; row < qr_modules; row++) {
        for (int col = 0; col < qr_modules; col++) {
            if (qrcodegen_getModule(qr_data, col, row)) {
                fb_draw_rect(fb, 
                           x + offset_x + col * module_size, 
                           y + offset_y + row * module_size,
                           module_size, module_size, 
                           COLOR_WHITE);
            }
        }
    }
    
    return 1;  // QR drawn successfully
}

void str_to_upper(char *str) {
    for (char *p = str; *p; p++) {
        *p = toupper((unsigned char)*p);
    }
}

void generate_display(Framebuffer *fb, DisplayConfig *cfg, FT_Face face) {
    fb_init(fb);
    
    char operator_text[32], network_text[8], hostname_text[32];
    strncpy(operator_text, cfg->operator, 31);
    strncpy(network_text, cfg->network_type, 7);
    strncpy(hostname_text, cfg->hostname, 31);
    
    if (cfg->uppercase) {
        str_to_upper(operator_text);
        str_to_upper(network_text);
        str_to_upper(hostname_text);
    }
    
    // Calculate QR position: centered horizontally, at top with margin
    int qr_x = (WIDTH - QR_SIZE) / 2;
    int qr_y = QR_TOP_MARGIN;
    
    if (cfg->show_qr) {
        char wifi_qr[256];
        snprintf(wifi_qr, sizeof(wifi_qr), 
                 "WIFI:T:WPA;S:%s;P:%s;;", cfg->ssid, cfg->password);
        
        // Try to draw QR, if it doesn't fit (returns 0), screen stays black
        fb_draw_qr(fb, wifi_qr, qr_x, qr_y, QR_SIZE);
    }
    // If no QR or QR too large: stay black (fb_init already cleared to black)
    
    int fontsz = 12;
    int line1_y = HEIGHT - fontsz - 3;
    int line2_y = HEIGHT - 3;
    
    fb_draw_text(fb, face, operator_text, 2, line1_y, fontsz);
    
    int net_width = fb_get_text_width(face, network_text, fontsz);
    fb_draw_text(fb, face, network_text, WIDTH - net_width - 2, line1_y, fontsz);
    
    fb_draw_text(fb, face, hostname_text, 2, line2_y, fontsz);
    
    // NEW: Format battery with charging indicator
    char battery_text[16];
    if (cfg->charging) {
        snprintf(battery_text, sizeof(battery_text), "+%d%%", cfg->battery);
    } else {
        snprintf(battery_text, sizeof(battery_text), "%d%%", cfg->battery);
    }
    
    int battery_width = fb_get_text_width(face, battery_text, fontsz);
    fb_draw_text(fb, face, battery_text, WIDTH - battery_width - 2, line2_y, fontsz);
}

void print_usage(const char *prog) {
    fprintf(stderr, "Usage: %s [OPTIONS]\n", prog);
    fprintf(stderr, "  -b NUM    Battery percentage (0-100)\n");
    fprintf(stderr, "  -c        Charging indicator (adds + prefix)\n");
    fprintf(stderr, "  -n NAME   Operator name\n");
    fprintf(stderr, "  -t TYPE   Network type (4G, LTE)\n");
    fprintf(stderr, "  -s SSID   WiFi SSID\n");
    fprintf(stderr, "  -p PASS   WiFi password\n");
    fprintf(stderr, "  -h HOST   Hostname\n");
    fprintf(stderr, "  -q        Show QR code (default: show logo)\n");
    fprintf(stderr, "  -u        Convert text to UPPERCASE\n");
}


int main(int argc, char *argv[]) {
    DisplayConfig cfg = {
        .battery = 100,
        .charging = 0,       // NEW: default not charging
        .operator = "Unknown",
        .network_type = "4G",
        .ssid = "WiFi",
        .password = "password",
        .hostname = "Router",
        .show_qr = 0,
        .uppercase = 0
    };
    
    int opt;
    while ((opt = getopt(argc, argv, "b:cn:t:s:p:h:qu")) != -1) {
        switch (opt) {
            case 'b': cfg.battery = atoi(optarg); break;
            case 'c': cfg.charging = 1; break;
            case 'n': strncpy(cfg.operator, optarg, 31); break;
            case 't': strncpy(cfg.network_type, optarg, 7); break;
            case 's': strncpy(cfg.ssid, optarg, 63); break;
            case 'p': strncpy(cfg.password, optarg, 63); break;
            case 'h': strncpy(cfg.hostname, optarg, 31); break;
            case 'q': cfg.show_qr = 1; break;
            case 'u': cfg.uppercase = 1; break;
            default:
                print_usage(argv[0]);
                return 1;
        }
    }
    
    FT_Library ft;
    if (FT_Init_FreeType(&ft)) {
        fprintf(stderr, "FreeType init failed\n");
        return 1;
    }
    
    FT_Face face;
    const char *fonts[] = {
        "/usr/share/fonts/ttf-dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/ttf-dejavu/DejaVuSans-Bold.ttf",
        NULL
    };
    
    int found = 0;
    for (int i = 0; fonts[i]; i++) {
        if (FT_New_Face(ft, fonts[i], 0, &face) == 0) {
            found = 1;
            break;
        }
    }
    
    if (!found) {
        fprintf(stderr, "No font found\n");
        FT_Done_FreeType(ft);
        return 1;
    }
    
    Framebuffer fb;
    generate_display(&fb, &cfg, face);
    
    fwrite(fb.data, sizeof(uint16_t), WIDTH * HEIGHT, stdout);
    
    FT_Done_Face(face);
    FT_Done_FreeType(ft);
    
    return 0;
}
