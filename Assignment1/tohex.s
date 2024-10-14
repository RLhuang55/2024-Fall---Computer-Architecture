.data
input_prompt:   .string "Enter a number: "
output_prompt:  .string "Converted hex: "
buffer:
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0  # Buffer to store the converted hex string, initialized to 0
hex_chars:
    .string "0123456789abcdef"  # Hexadecimal character table

.text
.globl main

main:
    # Output the prompt message "Enter a number: "
    la a0, input_prompt
    li a7, 4         # System call 4 (sys_write)
    li a1, 1         # Output to stdout (1)
    li a2, 17        # Set string length
    ecall
    
    li a0, 64       # Input number (for testing purposes)
    mv a3, a0       # Store the number in a3 (to be used in toHex)
    jal ra, clz32   # Call clz32 function
    mv a2, a0       # Move the result of clz to a2
    
    # Call toHex function to convert the number to hexadecimal
    jal ra, toHex
    
    # Output the converted hexadecimal string from buffer
    la a0, buffer
    li a7, 4         # System call 4 (sys_write)
    li a1, 1         # Output to stdout (1)
    li a2, 9         # Set string length
    ecall
    
    li a7, 10        # Exit program
    ecall

# toHex function to convert the number stored in a3 to a hexadecimal string
toHex:
    # a3 contains the input value, a2 contains the clz result
    li t0, 32
    sub t0, t0, a2          # t0 = 32 - clz(a2)
    addi t0, t0, 3
    srai t0, t0, 2          # t0 = (32 - clz + 3) / 4
    mv a4, t0               # Store the starting nibble in a4
    
    li t1, 0                # t1 = hex_index = 0
    addi t2, t0, -1         # t2 = starting_nibble - 1
    j convert_loop

convert_loop:
    blt t2, zero, end_loop  # If t2 < 0, exit the loop

    slli t3, t2, 2          # t3 = t2 * 4 (calculate shift amount)
    srl t4, a3, t3          # t4 = a3 >> shift (extract nibble)
    andi t4, t4, 0xF        # t4 = t4 & 0xF (keep the last 4 bits)
    
    # Convert the nibble value to the corresponding character
    li t5, 10               # Load constant 10
    blt t4, t5, convert_digit  # If nibble < 10, jump to convert_digit
    
    # If nibble >= 10, convert to letter character
    addi t4, t4, -10        # t4 = nibble - 10
    li t5, 97               # Load ASCII value of 'a' (97)
    add t4, t4, t5          # t4 = 'a' + (nibble - 10)
    j store_result
    
convert_digit:
    li t5, 48               # Load ASCII value of '0'
    add t4, t4, t5          # t4 = '0' + nibble

store_result:
    la t6, buffer           # Load address of buffer
    add t6, t6, t1          # Calculate address of buffer[hex_index]
    sb t4, 0(t6)            # Store character in buffer
    addi t1, t1, 1          # hex_index++

    # Process the next nibble
    addi t2, t2, -1         # t2--
    j convert_loop          # Jump back to loop

end_loop:
    # Append null terminator '\0'
    li t0, 0
    la t6, buffer           # Load address of buffer
    add t6, t6, t1          # Calculate the end position of the buffer
    sb t0, 0(t6)            # Store '\0' at the end of buffer

    ret

# clz32 function to count leading zeros
clz32:
    # Initialize n = 0
    li t0, 0         # t0 = n

    # Check if the upper 16 bits are 0
    li t1, 0xFFFF0000    # t1 = 0xFFFF0000
    and t2, a0, t1       # t2 = a0 & 0xFFFF0000
    bnez t2, skip_16     # If the upper 16 bits are not 0, skip
    addi t0, t0, 16      # n += 16
    slli a0, a0, 16      # x <<= 16

skip_16:
    # Check if the upper 8 bits are 0
    li t1, 0xFF000000    # t1 = 0xFF000000
    and t2, a0, t1       # t2 = a0 & 0xFF000000
    bnez t2, skip_8      # If the upper 8 bits are not 0, skip
    addi t0, t0, 8       # n += 8
    slli a0, a0, 8       # x <<= 8

skip_8:
    # Check if the upper 4 bits are 0
    li t1, 0xF0000000    # t1 = 0xF0000000
    and t2, a0, t1       # t2 = a0 & 0xF0000000
    bnez t2, skip_4      # If the upper 4 bits are not 0, skip
    addi t0, t0, 4       # n += 4
    slli a0, a0, 4       # x <<= 4

skip_4:
    # Check if the upper 2 bits are 0
    li t1, 0xC0000000    # t1 = 0xC0000000
    and t2, a0, t1       # t2 = a0 & 0xC0000000
    bnez t2, skip_2      # If the upper 2 bits are not 0, skip
    addi t0, t0, 2       # n += 2
    slli a0, a0, 2       # x <<= 2

skip_2:
    # Check if the highest bit is 0
    li t1, 0x80000000    # t1 = 0x80000000
    and t2, a0, t1       # t2 = a0 & 0x80000000
    bnez t2, end_clz     # If the highest bit is not 0, end
    addi t0, t0, 1       # n += 1

end_clz:
    # Return n (leading zeros count)
    mv a0, t0            # Return n
    ret                  # Return to main