#  Copyright (c) 2025 Grigoriy Efimov
# 
# Licensed under the MIT License. See LICENSE file for details.


.global success_exit, failed_exit, exit_with_code, littleEndianToBigEndian16bit

exit_with_code: #Use %rdi for return code 
    mov $60, %rax # sys_exit
    syscall

success_exit:
    mov $0, %rdi
    call exit_with_code

failed_exit:
    mov $1, %rdi
    call exit_with_code

littleEndianToBigEndian16bit: # for %rax
    xchg %ah, %al
    ret
