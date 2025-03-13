.equ AF_INET, 2
.equ SOCK_STREAM, 1
.equ IPPROTO_TCP, 0
.equ INADDR_ANY, 0x00000000
.equ MAX_CONNECTIONS, 3
.equ SOL_SOCKET, 1
.equ SO_REUSEADDR, 2

.data
    # struct sockaddr_in
    address:  # struct size=16 bytes, empty init
        .word AF_INET # Default type, not need to change
        .word 0x0 # You need to setup your port
        .long INADDR_ANY # Allow all IP
        .space 8 # Empty space

    .equ address.sin_family,address + 0
    .equ address.sin_port, address + 2
    .equ address.sin_addr, address + 4
.text
.global serve
serve: # %rdi port param (use only 2bits)
    call open_socket
    mov %rax, %rdi # From output to input
loop:
    call listen
    jmp loop # endless loop
    ret

open_socket: # %rdi port param (use only 2bits), return socket fd %rax

    mov %rdi, %rax
    call littleEndianToBigEndian16bit
    mov %ax, [address.sin_port] # Update port, with big endian

    mov $41, %rax # sys_socket
    mov $AF_INET, %rdi
    mov $SOCK_STREAM, %rsi
    mov $IPPROTO_TCP, %rdx
    syscall

    cmp $0, %rax
    jl failed_exit

    mov %rax, %rbx # Save socket fd

    sub $8, %rsp # Allocate 8 bytes for opt on stack
    movq $1, (%rsp)
    
    mov $54, %rax # sys_setsockopt
    mov %rbx, %rdi
    mov $SOL_SOCKET, %rsi
    mov $SO_REUSEADDR, %rdx
    mov %rsp, %r10
    mov $8, %r8
    syscall
    
    cmp $0, %rax
    jl failed_exit

    add $8, %rsp # Free memory for opt


    mov $49, %rax # sys_bind
    mov %rbx, %rdi
    lea address, %rsi
    mov $16, %rdx # struct size 16 bytes
    syscall
    
    cmp $0, %rax
    jl failed_exit

    mov %rbx, %rax # Return socket fd

    ret

listen: # socket fd in %rdi
    mov $50, %rax # sys_listen
    mov $MAX_CONNECTIONS, %rsi
    syscall
    ret

accept: # socket fd in %rdi
    
    mov $43, %rax # sys_accept
    lea address, %rsi
    mov $16, %rdx # struct size 16 bytes
    syscall
    ret