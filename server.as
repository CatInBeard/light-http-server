#  Copyright (c) 2025 Grigoriy Efimov
# 
# Licensed under the MIT License. See LICENSE file for details.

.equ AF_INET, 2
.equ SOCK_STREAM, 1
.equ IPPROTO_TCP, 0
.equ INADDR_ANY, 0x00000000
.equ MAX_CONNECTIONS, 3
.equ SOL_SOCKET, 1
.equ SO_REUSEADDR, 2
.equ INPUT_REQUEST_BUFFER_SIZE, 100
.equ MAX_REQUEST_SIZE, 10000

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


    hello_text:
        .ascii "HTTP/1.0 200 OK"
        .byte 10 # \n
        .ascii "Server: Light http server"
        .byte 10 # \n
        .ascii "Content-Type: text/html"
        .byte 10 # \n
        .ascii "Content-Length: 27"
        .byte 10 # \n
        .ascii "Connection: close"
        .byte 10 # \n
        .byte 10 # \n
        .ascii "<h1>Hello world from asm!</h1>"
    hello_text_end:
    .equ hello_text_length, hello_text_end - hello_text

.text
.global serve
serve: # %rdi port param (use only 2bits)
    call open_socket
    mov %rax, %rdi # From output to input
    call listen
    mov %rdi, %r15 #Save server fd
loop:
    mov %r15, %rdi #update first param as server fd
    call accept
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
    
    sub $16, %rsp # Allocate 16 bytes for sockaddr_in
    mov $43, %rax # sys_accept
    mov %rsp, %rsi
    mov $16, %rdx # struct size 16 bytes
    syscall
    add $16, %rsp # Free 16 bytes, sockaddr_in not used
    
    cmp $0, %rax
    jle exit_accept
    
    mov %rax, %rbx # Save client fd
    mov %rsp, %r12 # Save stack end
read_from_clent:

    sub $INPUT_REQUEST_BUFFER_SIZE, %rsp # Allocate N bytes for incomming data
    mov $0, %rax # sys_read
    mov %rbx, %rdi
    mov %rsp, %rsi
    mov $INPUT_REQUEST_BUFFER_SIZE, %rdx

    mov %rbx, %rdi
    cmp $0, %rax
    jle parse_answer

    movq    %rsp, %rax
    subq    %r12, %rax
    subq    $MAX_REQUEST_SIZE, %rax # If Request too large, answer 413
    jge     parse_answer

    jmp read_from_clent

parse_answer:
    call answer_hello_world

    
exit_accept_with_free:
    mov %r12, %rsp # Free stack
    
    mov $43, %rax # sys_close
    mov %rbx, %rdi # client fd

exit_accept:
    ret


answer_413:
    jmp exit_accept_with_free


answer_hello_world: #client_fd %rdi

    mov $1, %rax # sys_write
    lea hello_text, %rsi
    mov $hello_text_length, %rdx
    ret
    