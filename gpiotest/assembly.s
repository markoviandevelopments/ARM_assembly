    .section .data
dev_mem_str:
    .asciz "/dev/gpiomem"

// Adjust this constant as needed. Here it’s set to 100,000,000 iterations.
delay_const:
    .quad 100000000

    .section .text
    .global _start
_start:
    // Open /dev/gpiomem via openat(-100, "/dev/gpiomem", O_RDWR, 0)
    MOV     X0, #-100                   // AT_FDCWD = -100
    ADRP    X1, dev_mem_str             // Get page base of string
    ADD     X1, X1, :lo12:dev_mem_str    // Complete string address
    MOV     X2, #2                      // O_RDWR
    MOV     X3, #0                      // mode = 0
    MOV     X8, #56                     // Syscall: openat
    SVC     #0
    MOV     X19, X0                     // Save returned fd

    // mmap 0x100 bytes of /dev/gpiomem (covers needed registers)
    MOV     X0, #0                      // addr = NULL (let kernel choose)
    MOV     X1, #0x100                  // length = 0x100 bytes
    MOV     X2, #3                      // PROT_READ|PROT_WRITE = 3
    MOV     X3, #1                      // MAP_SHARED = 1
    MOV     X4, X19                     // fd from openat
    MOV     X5, #0                      // offset = 0
    MOV     X8, #222                    // Syscall: mmap
    SVC     #0
    MOV     X20, X0                     // X20 = mapped base address

    // Disable pull for GPIO27.
    // For GPIO16–31, the pull‑control register is at offset 0xE8.
    ADD     X25, X20, #0xE8             // X25 = address of GPIO_PUP_PDN_CNTRL_REG1
    LDR     W7, [X25]                   // Load current value into W7
    MOV     W8, #3                      // 0b11 mask
    LSL     W8, W8, #22                 // mask = 3 << 22 (covers GPIO27 bits)
    MVN     W8, W8                      // Invert mask: ones except in bits 22–23
    AND     W7, W7, W8                  // Clear bits 22–23 (disable pull)
    STR     W7, [X25]                   // Write back

    // Configure GPIO27 as output.
    // GPIO27 is in GPFSEL2 (offset 0x08). Its 3‑bit field is at bits [21:23].
    ADD     X21, X20, #0x08             // X21 = address of GPFSEL2
    LDR     W1, [X21]                   // Load current GPFSEL2
    MOV     W2, #7                      // 0b111 mask
    LSL     W2, W2, #21                 // mask = 7 << 21 (for GPIO27)
    MVN     W2, W2                      // Invert mask (to clear bits)
    AND     W1, W1, W2                  // Clear bits 21–23
    MOV     W2, #1                      // 0b001 = output mode
    LSL     W2, W2, #21                 // Shift into position
    ORR     W1, W1, W2                  // Set GPIO27 as output
    STR     W1, [X21]                   // Write back to GPFSEL2

    // Compute addresses for GPSET0 (offset 0x1C) and GPCLR0 (offset 0x28)
    ADD     X22, X20, #0x1C             // X22 = GPSET0 address
    ADD     X23, X20, #0x28             // X23 = GPCLR0 address

toggle_loop:
    // Set GPIO27 HIGH: write (1 << 27) to GPSET0
    MOV     X0, #1
    LSL     X0, X0, #27                // Bitmask: 1 << 27
    STR     W0, [X22]

    // Delay loop: load delay constant from memory, then count down.
    ADRP    X1, delay_const           // X1 = page address of delay_const
    ADD     X1, X1, :lo12:delay_const   // X1 = full address of delay_const
    LDR     X1, [X1]                  // X1 = 100,000,000 (delay iterations)
delay_loop_high:
    SUBS    X1, X1, #1
    BNE     delay_loop_high

    // Set GPIO27 LOW: write (1 << 27) to GPCLR0
    MOV     X0, #1
    LSL     X0, X0, #27                // Bitmask: 1 << 27
    STR     W0, [X23]

    // Delay loop: reload delay constant and count down.
    ADRP    X1, delay_const
    ADD     X1, X1, :lo12:delay_const
    LDR     X1, [X1]
delay_loop_low:
    SUBS    X1, X1, #1
    BNE     delay_loop_low

    B toggle_loop                   // Repeat forever
