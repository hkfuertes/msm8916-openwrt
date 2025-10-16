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

typedef struct {
    uint16_t data[WIDTH * HEIGHT];
} Framebuffer;

typedef struct {
    int battery;
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

void fb_draw_qr(Framebuffer *fb, const char *text, int x, int y, int size) {
    uint8_t qr_data[qrcodegen_BUFFER_LEN_MAX];
    uint8_t temp_buffer[qrcodegen_BUFFER_LEN_MAX];
    
    bool ok = qrcodegen_encodeText(text, temp_buffer, qr_data,
                                   qrcodegen_Ecc_LOW, 
                                   qrcodegen_VERSION_MIN,
                                   qrcodegen_VERSION_MAX,
                                   qrcodegen_Mask_AUTO, true);
    
    if (!ok) {
        fprintf(stderr, "QR generation failed\n");
        return;
    }
    
    int qr_size = qrcodegen_getSize(qr_data);
    int module_size = size / qr_size;
    
    for (int row = 0; row < qr_size; row++) {
        for (int col = 0; col < qr_size; col++) {
            if (qrcodegen_getModule(qr_data, col, row)) {
                fb_draw_rect(fb, 
                           x + col * module_size, 
                           y + row * module_size,
                           module_size, module_size, 
                           COLOR_WHITE);
            }
        }
    }
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
    
    if (cfg->show_qr) {
        char wifi_qr[256];
        snprintf(wifi_qr, sizeof(wifi_qr), 
                 "WIFI:T:WPA;S:%s;P:%s;;", cfg->ssid, cfg->password);
        
        int qr_size = 80;
        int qr_x = (WIDTH - qr_size) / 2 + 2;
        int qr_y = 12;
        fb_draw_qr(fb, wifi_qr, qr_x, qr_y, qr_size);
    }
    
    int fontsz = 15;
    int line1_y = HEIGHT - fontsz - 6;
    int line2_y = HEIGHT - 5;
    
    fb_draw_text(fb, face, operator_text, 3, line1_y, fontsz);
    
    int net_width = fb_get_text_width(face, network_text, fontsz);
    fb_draw_text(fb, face, network_text, WIDTH - net_width - 3, line1_y, fontsz);
    
    fb_draw_text(fb, face, hostname_text, 3, line2_y, fontsz);
    
    char battery_text[8];
    snprintf(battery_text, sizeof(battery_text), "%d%%", cfg->battery);
    int battery_width = fb_get_text_width(face, battery_text, fontsz);
    fb_draw_text(fb, face, battery_text, WIDTH - battery_width - 3, line2_y, fontsz);
}

void print_usage(const char *prog) {
    fprintf(stderr, "Usage: %s [OPTIONS]\n", prog);
    fprintf(stderr, "  -b NUM    Battery (0-100)\n");
    fprintf(stderr, "  -n NAME   Operator name\n");
    fprintf(stderr, "  -t TYPE   Network type (4G, LTE)\n");
    fprintf(stderr, "  -s SSID   WiFi SSID\n");
    fprintf(stderr, "  -p PASS   WiFi password\n");
    fprintf(stderr, "  -h HOST   Hostname\n");
    fprintf(stderr, "  -q        Show QR code\n");
    fprintf(stderr, "  -c        Convert text to UPPERCASE\n");
}

int main(int argc, char *argv[]) {
    DisplayConfig cfg = {
        .battery = 100,
        .operator = "Unknown",
        .network_type = "4G",
        .ssid = "WiFi",
        .password = "password",
        .hostname = "Router",
        .show_qr = 0,
        .uppercase = 0
    };
    
    int opt;
    while ((opt = getopt(argc, argv, "b:n:t:s:p:h:qc")) != -1) {
        switch (opt) {
            case 'b': cfg.battery = atoi(optarg); break;
            case 'n': strncpy(cfg.operator, optarg, 31); break;
            case 't': strncpy(cfg.network_type, optarg, 7); break;
            case 's': strncpy(cfg.ssid, optarg, 63); break;
            case 'p': strncpy(cfg.password, optarg, 63); break;
            case 'h': strncpy(cfg.hostname, optarg, 31); break;
            case 'q': cfg.show_qr = 1; break;
            case 'c': cfg.uppercase = 1; break;
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
        "/usr/share/fonts/DejaVuSansMono-Bold.ttf",
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
