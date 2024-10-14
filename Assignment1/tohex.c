#include<stdio.h>
#include<stdint.h>
static inline int clz32(uint32_t x) {
    int n = 0;

    // Check if the upper 16 bits are 0
    int mask = (x & 0xFFFF0000) == 0;
    n += mask * 16;
    x <<= mask * 16;

    // Check if the upper 8 bits are 0
    mask = (x & 0xFF000000) == 0;
    n += mask * 8;
    x <<= mask * 8;

    // Check if the upper 4 bits are 0
    mask = (x & 0xF0000000) == 0;
    n += mask * 4;
    x <<= mask * 4;

    // Check if the upper 2 bits are 0
    mask = (x & 0xC0000000) == 0;
    n += mask * 2;
    x <<= mask * 2;

    // Check if the highest bit is 0
    mask = (x & 0x80000000) == 0;
    n += mask * 1;

    // If x is 0, all bits are 0, return 32; otherwise, return the calculated n
    n += (x == 0) ? (32 - n) : 0;

    return n;
}

char* toHex(int num) {
    if (num == 0) {
        char* result = (char*)malloc(2 * sizeof(char));
        result[0] = '0';
        result[1] = '\0';
        return result;
    }

    // Convert signed integer to unsigned integer, handle negative numbers (two's complement)
    uint32_t x = (uint32_t)num;
    
    // Calculate the number of leading zeros
    int lz = clz32(x);
    
    // Determine how many nibbles to start processing (if x is non-zero, we have up to 8 nibbles)
    int starting_nibble = (32 - lz + 3) / 4; // +3 ensures rounding up to the nearest nibble
    
    // Allocate enough space to store the hexadecimal string (up to 8 digits + 1 null terminator)
    char* hex_str = (char*)malloc((starting_nibble + 1) * sizeof(char));

    int hex_index = 0;
    for (int i = starting_nibble - 1; i >= 0; i--) {
        int shift = i * 4;
        int rem = (x >> shift) & 0xF; // Extract nibble
        hex_str[hex_index++] = (rem < 10) ? ('0' + rem) : ('a' + (rem - 10));
    }

    // End the string
    hex_str[hex_index] = '\0';
    
    return hex_str;
}