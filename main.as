.equ DEFAULT_PORT, 4124

.global _start
.text
_start:

    mov $DEFAULT_PORT, %rdi
    call serve

    call success_exit
