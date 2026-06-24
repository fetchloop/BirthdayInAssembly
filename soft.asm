bits 64
default rel

extern printf
extern scanf

section .bss
    birthdays resb 4800 ; 100 records x 48 bytes (32 name + 16 date)
    choice resd 1
    count resb 1
    edit resd 1

section .data
    menu db "-=-=-=-=-=-=-=-=-=-=-=-=-", 10
         db " A Birthday S Manager M ", 10
         db "-=-=-=-=-=-=-=-=-=-=-=-=-", 10
         db "  1. View birthdays", 10
         db "  2. Add birthday", 10
         db "  3. Edit birthday", 10
         db "-=-=-=-=-=-=-=-=-=-=-=-=-", 10
         db "Page: ", 0

    fmt_input db "%d", 0
    fmt_string db "%s", 0
    fmt_record db "%s - %s", 10, 0

    prompt_name db "Enter name: ", 0
    prompt_birthday db "Enter date (YYYY-MM-DD): ", 0

    fmt_entry db "%d. %s - %s", 10, 0
    prompt_which db "Edit which?: ", 10, 0

section .text

global main

view_birthdays:
    sub rsp, 58h
    mov rcx, 0

    .loop:
        movzx rbx, byte [count]
        cmp rcx, rbx
        jge .done

        mov [rsp+40h], rcx ; save loop counter

        mov rax, rcx
        mov rbx, 48
        mul rbx
        lea rbx, [birthdays]
        add rax, rbx ; rax = birthdays + (i * 48)

        lea rcx, [fmt_record]
        mov rdx, rax ; name at record base
        lea r8, [rax+32] ; date at record base + 32
        call printf

        mov rcx, [rsp+40h] ; restore loop counter
        inc rcx
        jmp .loop

    .done:
        add rsp, 58h
        ret

add_birthday:
    sub rsp, 48h

    movzx rax, byte [count]
    mov rbx, 48
    mul rbx
    lea rbx, [birthdays]
    add rax, rbx ; rax = base of current record

    mov [rsp+30h], rax ; save record addr

    mov rcx, prompt_name
    call printf

    mov rax, [rsp+30h]
    mov rcx, fmt_string
    mov rdx, rax ; read name into record base
    call scanf

    mov rax, [rsp+30h]
    mov rcx, prompt_birthday
    call printf

    mov rax, [rsp+30h]
    add rax, 32
    mov rcx, fmt_string
    mov rdx, rax ; read date into record base + 32
    call scanf

    movzx rbx, byte [count]
    inc rbx
    mov [count], bl

    add rsp, 48h
    ret

edit_birthday:
    sub rsp, 58h
    mov rcx, 0

    .loop:
        movzx rbx, byte [count]
        cmp rcx, rbx
        jge .done

        mov [rsp+40h], rcx ; save loop counter

        mov rax, rcx
        mov rbx, 48
        mul rbx
        lea rbx, [birthdays]
        add rax, rbx ; rax = birthdays + (i * 48)

        lea rcx, [fmt_entry]
        mov rdx, [rsp+40h] ; index
        mov r8, rax ; name
        lea r9, [rax+32] ; date
        call printf

        mov rcx, [rsp+40h] ; restore loop counter
        inc rcx
        jmp .loop

    .done:
        lea rcx, [prompt_which]
        call printf

        mov rax, [rsp+40h]
        mov rcx, fmt_input
        mov rdx, rax ; read name into record base
        call scanf

        ; store input number and let user modify based on their int input. 


        add rsp, 58h
        ret

main:
.loop:
    sub rsp, 28h
    mov rcx, menu
    call printf
    add rsp, 28h

    sub rsp, 28h
    lea rcx, [fmt_input]
    lea rdx, [choice]
    call scanf
    add rsp, 28h

    mov eax, [choice]
    cmp rax, 1
    je .view
    cmp rax, 2
    je .add
    cmp rax, 3
    je .edit
    jmp .loop

.view:
    sub rsp, 28h
    call view_birthdays
    add rsp, 28h
    jmp .loop

.add:
    sub rsp, 28h
    call add_birthday
    add rsp, 28h
    jmp .loop

.edit:
    sub rsp, 28h
    call edit_birthday
    add rsp, 28h
    jmp .loop