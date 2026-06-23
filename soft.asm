bits 64
default rel

extern printf
extern scanf

section .bss
    birthdays resb 4800 ; 100 records x 48 bytes each
    choice resb 1
    count resb 1

section .data
    ; menu string
    menu db "-=-=-=-=-=-=-=-=-=-=-=-=-", 10
        db " A Birthday S Manager M", 10
        db "-=-=-=-=-=-=-=-=-=-=-=-=-", 10
        db "  1. View birthdays", 10
        db "  2. Add birthday", 10
        db "  3. Edit birthday", 10
        db "-=-=-=-=-=-=-=-=-=-=-=-=-", 10
        db "Page: ", 0

    ; the format strings for printf and scanf
    fmt_input db "%d", 0

    ; the format strings for reading name and birthday
    fmt_string db "%s", 0
    prompt_name db "Enter name: ", 0
    prompt_birthday db "Enter date (YYYY-MM-DD): ", 0

section .text

global main

view_birthdays:
    ; read from exePath/data.ini
    ret

add_birthday:
    ; read name and birthday from console
    sub rsp, 28h
    mov rcx, prompt_name
    call printf
    add rsp, 28h

    ; calculate base address of current record first
    movzx rax, byte [count]
    mov rbx, 48
    mul rbx
    add rax, birthdays ; rax = base of current record

    ; call scanf to read name into current record
    sub rsp, 28h
    mov rcx, fmt_string
    mov rdx, birthdays
    call scanfc
    add rsp, 28h

    movzx rax, byte [count]
    mov rbx, 48
    mul rbx
    add rax, birthdays
    add rax, 32
    ret

edit_birthday:
    ret

main:
    mov rcx, menu

    sub rsp, 28h
    call printf
    add rsp, 28h

    sub rsp, 28h
    mov rcx, fmt_input
    mov rdx, choice
    call scanf
    add rsp, 28h

    movzx rax, byte [choice]
    cmp rax, 1
    je view_birthdays
    cmp rax, 2
    je add_birthday
    cmp rax, 3
    je edit_birthday

    ret