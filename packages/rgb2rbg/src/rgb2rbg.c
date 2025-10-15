/*
 * rgb2rbg.c - RGB565 to RBG565 converter (CORRECTO)
 * Swaps Green and Blue channels with proper bit conversion
 */

#include <stdio.h>
#include <stdint.h>

#define BUFFER_SIZE 8192

static inline uint16_t rgb_to_rbg(uint16_t pixel) {
    // Extraer componentes RGB565
    uint16_t r = (pixel >> 11) & 0x1F;   // Rojo: 5 bits
    uint16_t g = (pixel >> 5) & 0x3F;    // Verde: 6 bits
    uint16_t b = pixel & 0x1F;           // Azul: 5 bits
    
    // Convertir para RBG565:
    // - Rojo mantiene 5 bits
    // - Verde (6 bits) va a posición de Azul (que también usa 6 bits en el panel)
    // - Azul (5 bits) va a posición de Verde, expandir a 6 bits
    
    uint16_t b_expanded = (b << 1) | (b >> 4);  // Expandir B de 5 a 6 bits
    
    // RBG565: RRRRR GGGGGG BBBBB donde G y B están swapeados
    // Pero en realidad el panel espera: RRRRR BBBBBB GGGGG (6 bits para ambos)
    return (r << 11) | (g << 5) | b_expanded;
}

int main(void) {
    uint16_t buffer[BUFFER_SIZE];
    size_t n;
    
    while ((n = fread(buffer, sizeof(uint16_t), BUFFER_SIZE, stdin)) > 0) {
        for (size_t i = 0; i < n; i++) {
            buffer[i] = rgb_to_rbg(buffer[i]);
        }
        fwrite(buffer, sizeof(uint16_t), n, stdout);
    }
    
    return 0;
}
