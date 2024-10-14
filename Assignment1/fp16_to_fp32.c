#include<stdio.h>
#include<stdint.h>
static inline uint32_t fp16_to_fp32(uint16_t h) {
   
    const uint32_t w = (uint32_t) h << 16;
    
    uint32_t sign = w & UINT32_C(0x80000000);
    
    const uint32_t nonsign = w & UINT32_C(0x7FFFFFFF);
    
    uint32_t renorm_shift = my_clz(nonsign);
    renorm_shift = renorm_shift > 5 ? renorm_shift - 5 : 0;
    
    const int32_t inf_nan_mask = ((int32_t)(nonsign + 0x04000000) >> 8) &
                                 INT32_C(0x7F800000);
    

    const int32_t zero_mask = (int32_t)(nonsign - 1) >> 31;
    
    return sign | ((((nonsign << renorm_shift >> 3) +
            ((0x70 - renorm_shift) << 23)) | inf_nan_mask) & ~zero_mask);
}