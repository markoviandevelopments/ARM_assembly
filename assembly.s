.global _start

.section .data
message:
    .asciz "HELLO WILL\n"

.section .text
_start:
    // syscall: write(stdout, message, length)
    mov x0, #1              // File descriptor 1 (stdout)
    ldr x1, =message        // Pointer to message
    mov x2, #11             // Message length (including newline)
    mov x8, #64             // syscall number for write
    svc #0                  // Make the system call

    // syscall: exit(0)
    mov x0, #0              // Status 0
    mov x8, #93             // syscall number for exit
    svc #0                  // Make the system call
