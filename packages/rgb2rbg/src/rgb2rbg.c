/*
 * rgb2rbg.c - RGB565 to RBG565 converter
 * Swaps Green and Blue channels
 */

#include <stdio.h>
#include <stdint.h>

#define BUFFER_SIZE 8192

static inline uint16_t swap_gb(uint16_t pixel) {
    // RGB565: RRRRR GGGGGG BBBBB
    //         15-11  10-5   4-0
    
    uint16_t r = pixel & 0xF800;        // Mantener Rojo (bits 15-11)
    uint16_t g = (pixel & 0x07E0) >> 5; // Verde (bits 10-5) → posición de Azul (bits 4-0)
    uint16_t b = (pixel & 0x001F) << 5; // Azul (bits 4-0) → posición de Verde (bits 10-5)
    
    // Problema: G tiene 6 bits, B tiene 5 bits
    // Verde (6 bits) → Azul (5 bits): recortar MSB
    uint16_t g5 = g >> 1;
    
    // Azul (5 bits) → Verde (6 bits): expandir replicando MSB
    uint16_t b6 = (b << 1) | (b >> 4);
    
    // RBG565: RRRRR BBBBBB GGGGG
    return r | b6 | g5;
}

int main(void) {
    uint16_t buffer[BUFFER_SIZE];
    size_t n;
    
    while ((n = fread(buffer, sizeof(uint16_t), BUFFER_SIZE, stdin)) > 0) {
        for (size_t i = 0; i < n; i++) {
            buffer[i] = swap_gb(buffer[i]);
        }
        fwrite(buffer, sizeof(uint16_t), n, stdout);
    }
    
    return 0;
}
