.global _start

// Raspberry Pi 4B GPIO Memory Map
.equ GPIO_BASE,  0xFE200000   // Base address (check with /proc/iomem)
.equ BLOCK_SIZE, 0x1000       // 4KB memory block
.equ GPFSEL2,  0x08           // GPIO Function Select Register 2
.equ GPSET0,   0x1C           // GPIO Set Register 0
.equ GPCLR0,   0x28           // GPIO Clear Register 0

.equ GPIO_27,  27             // GPIO pin number
.equ GPIO_27_FUNC, 1          // GPIO 27 as output (binary 001)
.equ DELAY_SEC, 1             // Delay in seconds

.section .text
_start:
    // 1. Open /dev/mem
    mov x8, #56               // syscall openat
    mov x0, #-100             // AT_FDCWD (relative to root)
    ldr x1, =file_path        // "/dev/mem"
    mov x2, #0x2              // O_RDWR
    mov x3, #0x1              // O_SYNC
    svc #0                    // syscall openat
    cmp x0, #0                // Check for failure
    blt exit_fail             // Exit if open failed
    mov x19, x0               // Store file descriptor

    // 2. mmap() to get access to GPIO
    mov x0, #0                // NULL (let kernel choose address)
    mov x1, #BLOCK_SIZE       // 4KB block size
    mov x2, #3                // PROT_READ | PROT_WRITE
    mov x3, #1                // MAP_SHARED
    mov x4, x19               // File descriptor (from open)
    mov x5, #GPIO_BASE        // GPIO base address
    mov x8, #222              // syscall mmap
    svc #0
    cmp x0, #0                // Check for failure
    blt exit_fail             // Exit if mmap failed
    mov x20, x0               // Store mapped GPIO base

    // 3. Set GPIO 27 as Output (word-aligned access)
    add x0, x20, #GPFSEL2     // GPIO Function Select Register
    ldr w1, [x0]              // Read current register (word-aligned)
    bic w1, w1, #(0b111 << 21) // Clear bits (GPIO 27: bits 21-23)
    orr w1, w1, #(GPIO_27_FUNC << 21) // Set function 001 (output)
    str w1, [x0]              // Write back

loop:
    // 4. Set GPIO 27 HIGH (word-aligned)
    add x0, x20, #GPSET0      // GPIO Set Register
    mov w1, #(1 << GPIO_27)   // Set bit for GPIO 27
    str w1, [x0]              // Write to GPSET0

    // 5. Sleep 1 second
    mov x0, #DELAY_SEC        // Sleep time
    mov x8, #35               // syscall sleep
    svc #0

    // 6. Set GPIO 27 LOW (word-aligned)
    add x0, x20, #GPCLR0      // GPIO Clear Register
    mov w1, #(1 << GPIO_27)   // Set bit for GPIO 27
    str w1, [x0]              // Write to GPCLR0

    // 7. Sleep 1 second
    mov x0, #DELAY_SEC        // Sleep time
    mov x8, #35               // syscall sleep
    svc #0

    // Repeat
    b loop

exit_fail:
    mov x0, #1               // Exit code 1 (failure)
    mov x8, #93              // syscall exit
    svc #0

// File path for /dev/mem
.section .data
file_path:
    .asciz "/dev/mem"
