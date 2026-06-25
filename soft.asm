bits 64
default rel

section .bss
    birthdays resb 4800 ; 100 records x 48 bytes (32 name + 16 date)
    choice resd 1
    count resb 1
    edit resd 1
    filehandle  resq 1 ; fopen returns a 64bit ptr
    linebuf resb 64 ; temp buf for fgets
    array_idx resb 1
    today_month resd 1
    today_day resd 1
    swap_tmp resb 48
    bday_month resd 1
    bday_day resd 1
    today_doy resd 1
    days_j resd 1

section .data
    menu db "-=-=-=-=-=-=-=-=-=-=-=-=-", 10
         db " A Birthday S Manager M ", 10
         db "-=-=-=-=-=-=-=-=-=-=-=-=-", 10
         db "  1. View birthdays", 10
         db "  2. Add birthday", 10
         db "  3. Edit birthday", 10
         db "  4. Remove birthday", 10
         db "-=-=-=-=-=-=-=-=-=-=-=-=-", 10
         db "Page: ", 0

    fmt_input db "%d", 0
    fmt_string db "%s", 0
    fmt_record db "%s - %s", 0

    prompt_name db "Enter name: ", 0
    prompt_birthday db "Enter date (YYYY-MM-DD): ", 0

    fmt_entry db "%d. %s - %s", 10, 0
    prompt_which db "Edit which?: ", 0

    cls db 27, "[3J", 27, "[2J", 27, "[H", 0
    prompt_enter db "Press enter to continue...", 0

    filename db "birthdays.ini", 0
    mode_r db "r", 0
    mode_w db "w", 0
    fmt_save db "%s:%s", 10, 0 ; format for writing each line

    fmt_load db "%31[^:]:%15s", 0

    until_bday db " | in: %dd", 10, 0

    fmt_date db "%*d-%d-%d", 0

section .text

; i'm a fraud, i know
extern printf
extern scanf
extern getchar
extern fopen
extern fclose
extern fprintf
extern fgets
extern sscanf
extern time
extern localtime

global main

save_birthdays:
    sub rsp, 58h

    mov rcx, filename
    mov rdx, mode_w
    call fopen
    mov [filehandle], rax

    mov rcx, 0

    ; loop all records in file
    .loop:
        movzx rbx, byte [count]
        cmp rcx, rbx
        jge .done

        mov [rsp+40h], rcx

        mov rax, rcx
        mov rbx, 48
        mul rbx
        lea rbx, [birthdays]
        add rax, rbx

        mov rcx, [filehandle]
        mov rdx, fmt_save
        mov r8, rax
        lea r9, [rax+32]
        call fprintf

        mov rcx, [rsp+40h]
        inc rcx
        jmp .loop

    .done:
        mov rcx, [filehandle]
        call fclose

        add rsp, 58h
        ret

load_birthdays:
    sub rsp, 58h

    mov rcx, filename
    mov rdx, mode_r
    call fopen
    mov [filehandle], rax

    cmp rax, 0
    je .no_file

    .loop:
        mov rcx, linebuf
        mov rdx, 64
        mov r8, [filehandle]
        call fgets
        cmp rax, 0
        je .done

        movzx rax, byte [count]
        mov rbx, 48
        mul rbx
        lea rbx, [birthdays]
        add rax, rbx

        mov [rsp+40h], rax ; save record addr first

        mov rcx, linebuf
        mov rdx, fmt_load
        mov r8, [rsp+40h] ; name ptr
        mov r9, [rsp+40h]
        add r9, 32 ; date ptr

        call sscanf

        movzx rbx, byte [count]
        inc rbx
        mov [count], bl
        jmp .loop

    .done:
        mov rcx, [filehandle]
        call fclose

        call sort_birthdays

        add rsp, 58h
        ret

    .no_file:
        add rsp, 58h
        ret

sort_birthdays:
    sub rsp, 58h

    xor ecx, ecx
    call time
    mov [rsp+40h], rax
    lea rcx, [rsp+40h]
    call localtime
    mov ecx, [rax+12]
    mov [today_day], ecx
    mov ecx, [rax+16]
    inc ecx
    mov [today_month], ecx

    mov eax, [today_month]
    imul eax, 30
    mov ecx, [today_day]
    add eax, ecx
    mov [today_doy], eax

    ; loop i from 0 to count-2
    mov dword [rsp+30h], 0 ; i = 0
    .outer:
        movzx eax, byte [count]
        dec eax
        cmp dword [rsp+30h], eax
        jge .sort_done

        ; loop j from 0 to count-i-2
        mov dword [rsp+38h], 0 ; j = 0
        .inner:
            movzx eax, byte [count]
            dec eax
            sub eax, [rsp+30h]
            cmp dword [rsp+38h], eax
            jge .inner_done

            ; get addr of record[j]
            mov eax, [rsp+38h]
            imul eax, 48
            lea rbx, [birthdays]
            add rax, rbx ; rax = record[j]
            mov [rsp+48h], rax

            ; parse date of record[j]
            lea rcx, [rax+32]
            mov rdx, fmt_date
            lea r8, [bday_month]
            lea r9, [bday_day]
            call sscanf

            mov eax, [bday_month]
            imul eax, 30
            mov ecx, [bday_day]
            add eax, ecx
            sub eax, [today_doy] ; days_until[j]
            jns .j_pos
            add eax, 365
            .j_pos:
            mov [days_j], eax ; r11d = days_until[j]

            ; get addr of record[j+1]
            mov eax, [rsp+38h]
            inc eax
            imul eax, 48
            lea rbx, [birthdays]
            add rax, rbx ; rax = record[j+1]
            mov [rsp+50h], rax

            ; parse date of record[j+1]
            lea rcx, [rax+32]
            mov rdx, fmt_date
            lea r8, [bday_month]
            lea r9, [bday_day]
            call sscanf

            mov eax, [bday_month]
            imul eax, 30
            mov ecx, [bday_day]
            add eax, ecx
            sub eax, [today_doy] ; days_until[j+1]
            jns .j1_pos
            add eax, 365
            .j1_pos: ; eax = days_until[j+1]

            ; if (days_until[j] <= days_until[j+1]): no swap needed
            cmp [days_j], eax
            jle .no_swap

            ; swap record[j] && record[j+1] w/ swap_tmp
            mov rsi, [rsp+48h] ; record[j]
            mov rdi, [rsp+50h] ; record[j+1]
            lea rdx, [swap_tmp]

            mov r8, [rsi]
            mov [rdx], r8
            mov r8, [rsi+8]
            mov [rdx+8], r8
            mov r8, [rsi+16]
            mov [rdx+16], r8
            mov r8, [rsi+24]
            mov [rdx+24], r8
            mov r8, [rsi+32]
            mov [rdx+32], r8
            mov r8, [rsi+40]
            mov [rdx+40], r8

            mov r8, [rdi]
            mov [rsi], r8
            mov r8, [rdi+8]
            mov [rsi+8], r8
            mov r8, [rdi+16]
            mov [rsi+16], r8
            mov r8, [rdi+24]
            mov [rsi+24], r8
            mov r8, [rdi+32]
            mov [rsi+32], r8
            mov r8, [rdi+40]
            mov [rsi+40], r8

            mov r8, [rdx]
            mov [rdi], r8
            mov r8, [rdx+8]
            mov [rdi+8], r8
            mov r8, [rdx+16]
            mov [rdi+16], r8
            mov r8, [rdx+24]
            mov [rdi+24], r8
            mov r8, [rdx+32]
            mov [rdi+32], r8
            mov r8, [rdx+40]
            mov [rdi+40], r8

            .no_swap:
                mov eax, [rsp+38h]
                inc eax
                mov [rsp+38h], eax
                jmp .inner

        .inner_done:
            mov eax, [rsp+30h]
            inc eax
            mov [rsp+30h], eax
            jmp .outer

    .sort_done:
        add rsp, 58h
        ret

view_birthdays:
    sub rsp, 58h

    mov rcx, cls
    call printf

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

        mov [rsp+48h], rax ; save record addr

        lea rcx, [fmt_record]
        mov rdx, rax ; name at record base
        lea r8, [rax+32] ; date at record base + 32
        call printf

        ; parse date and compute days_until
        mov rax, [rsp+48h]
        lea rcx, [rax+32]
        mov rdx, fmt_date
        lea r8, [bday_month]
        lea r9, [bday_day]
        call sscanf

        mov eax, [bday_month]
        imul eax, 30
        mov ecx, [bday_day]
        add eax, ecx
        sub eax, [today_doy]
        jns .pos
        add eax, 365
        .pos:

        mov rcx, until_bday
        mov edx, eax
        call printf

        mov rcx, [rsp+40h] ; restore loop counter
        inc rcx
        jmp .loop

    .done:
        lea rcx, [prompt_enter]
        call printf
        call getchar ; eat leftovers, yummy
        call getchar ; wait for input
        add rsp, 58h
        ret

add_birthday:
    sub rsp, 48h

    mov rcx, cls
    call printf

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

    call sort_birthdays
    call save_birthdays

    add rsp, 48h
    ret

edit_birthday:
    sub rsp, 58h

    mov rcx, cls
    call printf

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

        lea rcx, [fmt_input]
        lea rdx, [edit]
        call scanf

        mov eax, [edit] ; edit is dword so can't use movzx
        mov rbx, 48
        mul rbx
        lea rbx, [birthdays]
        add rax, rbx

        mov [rsp+40h], rax ; store result

        ; actual edit
        mov rcx, prompt_name
        call printf

        mov rax, [rsp+40h]
        mov rcx, fmt_string
        mov rdx, rax ; read name into record base
        call scanf

        mov rax, [rsp+40h]
        mov rcx, prompt_birthday
        call printf

        mov rax, [rsp+40h]
        add rax, 32
        mov rcx, fmt_string
        mov rdx, rax ; read date into record base + 32
        call scanf

        call sort_birthdays
        call save_birthdays
        add rsp, 58h ; free shadow space
        ret

remove_birthday:
    sub rsp, 58h

    mov rcx, cls
    call printf

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

        lea rcx, [fmt_input]
        lea rdx, [edit]
        call scanf

        mov eax, [edit] ; edit is dword so can't use movzx
        mov rbx, 48
        mul rbx
        lea rbx, [birthdays]
        add rax, rbx

        mov [rsp+40h], rax ; store result

        mov eax, [edit]
        mov [rsp+40h], rax ; save idx to remove

        .shift:
            mov rax, [rsp+40h]
            movzx rbx, byte [count]
            dec rbx
            cmp rax, rbx
            jge .shift_done

            ; calculate address of record[i]
            mov rcx, [rsp+40h]
            imul rcx, rcx, 48
            lea rbx, [birthdays]
            add rcx, rbx

            ; copy 48 bytes from record[i+1] to record[i]
            mov r8, [rcx+48]
            mov [rcx], r8
            mov r8, [rcx+56]
            mov [rcx+8], r8
            mov r8, [rcx+64]
            mov [rcx+16], r8
            mov r8, [rcx+72]
            mov [rcx+24], r8
            mov r8, [rcx+80]
            mov [rcx+32], r8
            mov r8, [rcx+88]
            mov [rcx+40], r8

            mov rax, [rsp+40h]
            inc rax
            mov [rsp+40h], rax
            jmp .shift

        .shift_done:
            movzx rbx, byte [count]
            dec rbx
            mov [count], bl
        
        call sort_birthdays
        call save_birthdays
        add rsp, 58h ; free shadow space
        ret

main:
    sub rsp, 28h
    call load_birthdays
    add rsp, 28h

    .loop:
        sub rsp, 28h
        mov rcx, cls
        call printf
        add rsp, 28h

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
        cmp rax, 4
        je .remove
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

    .remove:
        sub rsp, 28h
        call remove_birthday
        add rsp, 28h
        jmp .loop