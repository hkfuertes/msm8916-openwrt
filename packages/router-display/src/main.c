#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <getopt.h>
#include <unistd.h>
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
} DisplayConfig;

void fb_init(Framebuffer *fb) {
    memset(fb->data, 0, sizeof(fb->data));
}

void fb_put_pixel(Framebuffer *fb, int x, int y, uint16_t color) {
    if (x >= 0 && x < WIDTH && y >= 0 && y < HEIGHT) {
        fb->data[y * WIDTH + x] = color;
    }
}

void fb_draw_rect(Framebuffer *fb, int x, int y, int w, int h, uint16_t color) {
    for (int j = 0; j < h; j++) {
        for (int i = 0; i < w; i++) {
            fb_put_pixel(fb, x + i, y + j, color);
        }
    }
}

void fb_draw_char(Framebuffer *fb, FT_Face face, char c, int x, int y, int size) {
    FT_Set_Pixel_Sizes(face, 0, size);
    
    if (FT_Load_Char(face, c, FT_LOAD_RENDER)) {
        return;
    }
    
    FT_GlyphSlot slot = face->glyph;
    FT_Bitmap bitmap = slot->bitmap;
    
    for (unsigned int row = 0; row < bitmap.rows; row++) {
        for (unsigned int col = 0; col < bitmap.width; col++) {
            int px = x + slot->bitmap_left + col;
            int py = y - slot->bitmap_top + row;
            
            unsigned char gray = bitmap.buffer[row * bitmap.pitch + col];
            if (gray > 128) {
                fb_put_pixel(fb, px, py, COLOR_WHITE);
            }
        }
    }
}

void fb_draw_text(Framebuffer *fb, FT_Face face, const char *text, int x, int y, int size) {
    int pen_x = x;
    
    for (const char *p = text; *p; p++) {
        FT_Set_Pixel_Sizes(face, 0, size);
        
        if (FT_Load_Char(face, *p, FT_LOAD_RENDER)) {
            continue;
        }
        
        FT_GlyphSlot slot = face->glyph;
        FT_Bitmap bitmap = slot->bitmap;
        
        for (unsigned int row = 0; row < bitmap.rows; row++) {
            for (unsigned int col = 0; col < bitmap.width; col++) {
                int px = pen_x + slot->bitmap_left + col;
                int py = y - slot->bitmap_top + row;
                
                unsigned char gray = bitmap.buffer[row * bitmap.pitch + col];
                if (gray > 128) {
                    fb_put_pixel(fb, px, py, COLOR_WHITE);
                }
            }
        }
        
        pen_x += slot->advance.x >> 6;
    }
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

void generate_display(Framebuffer *fb, DisplayConfig *cfg, FT_Face face) {
    fb_init(fb);
    
    // 1. Hostname arriba derecha
    int text_w = strlen(cfg->hostname) * 6;
    fb_draw_text(fb, face, cfg->hostname, WIDTH - text_w - 2, 10, 9);
    
    // 2. QR WiFi centrado
    char wifi_qr[256];
    snprintf(wifi_qr, sizeof(wifi_qr), 
             "WIFI:T:WPA;S:%s;P:%s;;", cfg->ssid, cfg->password);
    fb_draw_qr(fb, wifi_qr, 16, 16, 96);
    
    // 3. Operador + tipo red
    fb_draw_text(fb, face, cfg->operator, 2, 118, 8);
    int net_w = strlen(cfg->network_type) * 5;
    fb_draw_text(fb, face, cfg->network_type, WIDTH - net_w - 2, 118, 8);
    
    // 4. Barra batería
    char bar[64];
    int bar_chars = 18;
    int filled = (bar_chars * cfg->battery) / 100;
    
    for (int i = 0; i < filled; i++) {
        bar[i] = 0x2588;  // █
    }
    for (int i = filled; i < bar_chars; i++) {
        bar[i] = 0x2591;  // ░
    }
    sprintf(bar + bar_chars, " %d%%", cfg->battery);
    
    fb_draw_text(fb, face, bar, 0, 126, 8);
}

void print_usage(const char *prog) {
    fprintf(stderr, "Usage: %s [OPTIONS]\n", prog);
    fprintf(stderr, "  -b NUM    Battery (0-100)\n");
    fprintf(stderr, "  -n NAME   Operator name\n");
    fprintf(stderr, "  -t TYPE   Network type (4G, LTE)\n");
    fprintf(stderr, "  -s SSID   WiFi SSID\n");
    fprintf(stderr, "  -p PASS   WiFi password\n");
    fprintf(stderr, "  -h HOST   Hostname\n");
}

int main(int argc, char *argv[]) {
    DisplayConfig cfg = {
        .battery = 100,
        .operator = "Unknown",
        .network_type = "4G",
        .ssid = "WiFi",
        .password = "password",
        .hostname = "Router"
    };
    
    int opt;
    while ((opt = getopt(argc, argv, "b:n:t:s:p:h:")) != -1) {
        switch (opt) {
            case 'b': cfg.battery = atoi(optarg); break;
            case 'n': strncpy(cfg.operator, optarg, 31); break;
            case 't': strncpy(cfg.network_type, optarg, 7); break;
            case 's': strncpy(cfg.ssid, optarg, 63); break;
            case 'p': strncpy(cfg.password, optarg, 63); break;
            case 'h': strncpy(cfg.hostname, optarg, 31); break;
            default:
                print_usage(argv[0]);
                return 1;
        }
    }
    
    // Init FreeType
    FT_Library ft;
    if (FT_Init_FreeType(&ft)) {
        fprintf(stderr, "FreeType init failed\n");
        return 1;
    }
    
    FT_Face face;
    const char *fonts[] = {
        "/usr/share/fonts/dejavu/DejaVuSansMono.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
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
    
    // Generate
    Framebuffer fb;
    generate_display(&fb, &cfg, face);
    
    // Output raw RGB565
    fwrite(fb.data, sizeof(uint16_t), WIDTH * HEIGHT, stdout);
    
    // Cleanup
    FT_Done_Face(face);
    FT_Done_FreeType(ft);
    
    return 0;
}
