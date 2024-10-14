#include<stdio.h>
#include<stdint.h>
static inline int clz32(uint32_t x) {
    int n = 0;
    
    // Check if the upper 16 bits are 0
    int mask = ((x & 0xFFFF0000) == 0);
    n += mask << 4;          // mask * 16
    x <<= mask << 4;         // x <<= (mask * 16)
    
    // Check if the upper 8 bits are 0
    mask = ((x & 0xFF000000) == 0);
    n += mask << 3;          // mask * 8
    x <<= mask << 3;         // x <<= (mask * 8)
    
    // Check if the upper 4 bits are 0
    mask = ((x & 0xF0000000) == 0);
    n += mask << 2;          // mask * 4
    x <<= mask << 2;         // x <<= (mask * 4)
    
    // Check if the upper 2 bits are 0
    mask = ((x & 0xC0000000) == 0);
    n += mask << 1;          // mask * 2
    x <<= mask << 1;         // x <<= (mask * 2)
    
    // Check if the highest bit is 0
    mask = ((x & 0x80000000) == 0);
    n += mask;               // mask * 1

    // If x is 0, return 32, otherwise return n
    return (x == 0) ? 32 : n;
}