.global _start

// Raspberry Pi 4B GPIO Registers (Offset from `/dev/gpiomem` Direct Access)
.equ GPFSEL2,  0x08           // GPIO Function Select Register 2
.equ GPSET0,   0x1C           // GPIO Pin Output Set Register 0
.equ GPCLR0,   0x28           // GPIO Pin Output Clear Register 0

.equ GPIO_27,  27             // GPIO pin number
.equ GPIO_27_FUNC, 1          // GPIO 27 as output (binary 001)
.equ DELAY_SEC, 1             // Delay in seconds

.section .text
_start:
    // 1. Open /dev/gpiomem (DO NOT use mmap with /dev/gpiomem)
    mov x8, #56               // syscall openat
    mov x0, #-100             // AT_FDCWD (relative to root)
    ldr x1, =file_path        // "/dev/gpiomem"
    mov x2, #0x2              // O_RDWR
    svc #0                    // syscall openat
    cmp x0, #0                // Check for failure
    blt exit_fail             // Exit if open failed
    mov x20, x0               // Store file descriptor

    // 2. Set GPIO 27 as Output (word-aligned access)
    mov x0, x20               // File descriptor
    add x1, x0, #GPFSEL2      // GPIO Function Select Register
    ldr w2, [x1]              // Read current register (word-aligned)
    bic w2, w2, #(0b111 << 21) // Clear bits (GPIO 27: bits 21-23)
    orr w2, w2, #(GPIO_27_FUNC << 21) // Set function 001 (output)
    str w2, [x1]              // Write back

loop:
    // 3. Set GPIO 27 HIGH (word-aligned)
    mov x0, x20               // File descriptor
    add x1, x0, #GPSET0       // GPIO Set Register
    mov w2, #(1 << GPIO_27)   // Set bit for GPIO 27
    str w2, [x1]              // Write to GPSET0

    // 4. Sleep 1 second
    mov x0, #DELAY_SEC        // Sleep time
    mov x8, #35               // syscall sleep
    svc #0

    // 5. Set GPIO 27 LOW (word-aligned)
    mov x0, x20               // File descriptor
    add x1, x0, #GPCLR0       // GPIO Clear Register
    mov w2, #(1 << GPIO_27)   // Set bit for GPIO 27
    str w2, [x1]              // Write to GPCLR0

    // 6. Sleep 1 second
    mov x0, #DELAY_SEC        // Sleep time
    mov x8, #35               // syscall sleep
    svc #0

    // Repeat
    b loop

exit_fail:
    mov x0, #1               // Exit code 1 (failure)
    mov x8, #93              // syscall exit
    svc #0

// File path for /dev/gpiomem
.section .data
file_path:
    .asciz "/dev/gpiomem"
