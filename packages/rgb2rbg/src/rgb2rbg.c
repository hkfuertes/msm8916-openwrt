/*
 * rgb2rbg.c - RGB565 to RBG converter
 * Copyright (C) 2025
 * License: GPL-2.0
 */

#include <stdio.h>
#include <stdint.h>
#include <unistd.h>

#define BUFFER_SIZE 8192

static inline uint16_t swap_gb(uint16_t pixel) {
    return (pixel & 0xF800) |           // Keep R (bits 15-11)
           ((pixel & 0x001F) << 5) |    // B to G position
           ((pixel & 0x07E0) >> 5);     // G to B position
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
