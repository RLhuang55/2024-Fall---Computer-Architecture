.data
input_prompt:   .string "Enter a 16-bit floating point value (hex): "
output_prompt:  .string "Converted 32-bit floating point value (hex): "
buffer: .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.text
.globl main

main:
    # Input prompt (optional)
    # You can implement user input as needed
    # Here it assumes the user input has been loaded into a3

    li a3, 0x0001        # Load a 16-bit floating point number (for testing, change this value to test other cases)

    # Jump to the fp16_to_fp32 function
    jal ra, fp16_to_fp32     # Call fp16_to_fp32 function
    mv t0, a0                # Store the returned 32-bit floating-point result

    # End program
    li a7, 10                # System call number 10 (sys_exit)
    ecall

# clz32 function to count leading zeros
clz32:
    addi sp, sp, -16         # Allocate stack space
    sw s0, 0(sp)             # Save s0
    sw s1, 4(sp)             # Save s1

    li s0, 0                 # Initialize n = 0

    li s1, 0xFFFF0000        # Check if the upper 16 bits are 0
    and t2, a0, s1           
    bnez t2, skip_16         # If the upper 16 bits are not 0, skip
    addi s0, s0, 16          
    slli a0, a0, 16          # x <<= 16

skip_16:
    li s1, 0xFF000000        # Check if the upper 8 bits are 0
    and t2, a0, s1
    bnez t2, skip_8
    addi s0, s0, 8
    slli a0, a0, 8

skip_8:
    li s1, 0xF0000000        # Check if the upper 4 bits are 0
    and t2, a0, s1
    bnez t2, skip_4
    addi s0, s0, 4
    slli a0, a0, 4

skip_4:
    li s1, 0xC0000000        # Check if the upper 2 bits are 0
    and t2, a0, s1
    bnez t2, skip_2
    addi s0, s0, 2
    slli a0, a0, 2

skip_2:
    li s1, 0x80000000        # Check if the highest bit is 0
    and t2, a0, s1
    bnez t2, end_clz
    addi s0, s0, 1

end_clz:
    mv a0, s0                # Return n
    lw s0, 0(sp)             # Restore s0
    lw s1, 4(sp)             # Restore s1
    addi sp, sp, 16          # Reclaim stack space
    ret

# fp16_to_fp32 function
fp16_to_fp32:
    addi sp, sp, -16         # Allocate stack space
    sw s0, 0(sp)             # Save s0
    sw s1, 4(sp)             # Save s1
    sw s2, 8(sp)             # Save s2
    sw ra, 12(sp)            # Save ra

    # Extract the sign bit: s = (a3 >> 15) & 1
    srli s1, a3, 15          # s1 = a3 >> 15
    andi s1, s1, 0x1         # s1 = s1 & 1
    slli s1, s1, 31          # Move the sign bit to bit 31

    # Extract the exponent: e = (a3 >> 10) & 0x1F
    srli s2, a3, 10          # s2 = a3 >> 10
    andi s2, s2, 0x1F        # s2 = s2 & 0x1F

    # Extract the mantissa: m = a3 & 0x3FF
    andi t0, a3, 0x3FF       # t0 = a3 & 0x3FF

    # Check if it is a special case: e == 31
    li t1, 31
    beq s2, t1, handle_special

    # Check if it is zero or subnormal: e == 0
    li t1, 0
    beq s2, t1, handle_zero_or_subnormal

    # Normal value
    # e_fp32 = e - 15 + 127 = e + 112
    addi t1, s2, 112          # t1 = e + 112
    slli t1, t1, 23           # t1 = e_fp32 << 23

    # mantissa_fp32 = m << 13
    slli t0, t0, 13           # t0 = m << 13

    # Combine sign, exponent, and mantissa
    or a0, s1, t1             # a0 = sign | exponent
    or a0, a0, t0             # a0 = sign | exponent | mantissa
    j end_fp16_to_fp32

handle_special:
    # Check if mantissa is 0: m == 0
    beqz t0, set_infinity

    # If not infinity, it is NaN, set mantissa
    # e_fp32 = 255
    li t1, 255
    slli t1, t1, 23           # t1 = 255 << 23 = 0x7F800000

    # mantissa_fp32 = m << 13
    slli t0, t0, 13           # t0 = m << 13

    # Combine sign, exponent, and mantissa
    or a0, s1, t1             # a0 = sign | 0x7F800000
    or a0, a0, t0             # a0 = sign | 0x7F800000 | mantissa
    j end_fp16_to_fp32

set_infinity:
    # e_fp32 = 255, mantissa = 0
    li t1, 255
    slli t1, t1, 23           # t1 = 255 << 23 = 0x7F800000

    # Combine sign, exponent, and mantissa = 0
    or a0, s1, t1             # a0 = sign | 0x7F800000
    j end_fp16_to_fp32

handle_zero_or_subnormal:
    # Check if zero: m == 0
    beqz t0, set_zero

    # Handle subnormal
    # Convert fp16 subnormal number to fp32 normal number
    # e_fp32 = 113 (127 - 15 +1)
    li t1, 103
    slli t1, t1, 23           # t1 = 113 << 23 =0x71000000

    # Combine sign, exponent, and mantissa
    or a0, s1, t1             # a0 = sign | 0x71000000
    j end_fp16_to_fp32

set_zero:
    # Combine sign, exponent = 0, mantissa = 0
    mv a0, s1                 # a0 = sign | 0
    j end_fp16_to_fp32

end_fp16_to_fp32:
    lw s0, 0(sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret