; This version does not support periodic boundary conditions
; registers:
;   arguments:
;    rdi - int* size
;    rsi - Board*** board
;    rdx - Board*** copy
;   others:
;

section .data
ptr_size:
    db 0x8
fmt:
    db `>DEBUG: %x\n`, 0
fmt1:
    db `>DEBUG: i %d\n`, 0
fmt2:
    db `>DEBUG: j %d\n`, 0

section .text
    global _make_simulation
    extern _printf

%macro pushallimusing 0
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
%endmacro

%macro popallimusing 0
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
%endmacro

%macro dbg_print 2
    pushallimusing
    sub rsp, 0x8 ; align stack for OS X
    lea rdi, [rel %2]
    mov rsi, %1
    xor rax, rax
    call _printf
    add rsp, 0x8
    popallimusing
%endmacro

%macro save_state 0
    push rbp
    mov rbp, rsp
    sub rsp, 0x10
    push rbx
    push r12
    push r13
    push r14
    push r15
%endmacro

%macro restore_state 0
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
%endmacro

%macro getsize_row 1
    mov %1, [rdi]
%endmacro

%macro getsize_col 1
    mov %1, [rdi + 4]
%endmacro

%macro get_board_cell 4 ; get_board_cell(Board*, i, j)
    mov %4, [%1]
    mov %4, [%4 + %2 * 8]
    mov %4, [%4 + %3]
    and %4, 0x1
%endmacro

%macro write_board_cell 1
    mov r12, [rdx]
    mov r12, [r12 + rax * 8]
    add r12, rbx
    mov [r12], %1
%endmacro

%macro flip_cell 0
    get_board_cell rsi, rax, rbx, r11
    cmp r11, 1
    jne %%.not_dead
    cmp rcx, 2
    jl %%.change_cell
    cmp rcx, 3
    jg %%.change_cell
    jmp %%.dont_change
%%.not_dead:
    cmp rcx, 3
    je %%.change_cell
%%.dont_change:
    write_board_cell r11
    jmp %%.done_writing
%%.change_cell:
    not r11
    and r11, 0x1
    write_board_cell r11
%%.done_writing:
%endmacro

%macro nbr_from 2
; %1 - i
; %2 - j
;    i == -1
    mov r8, rax
    mov r9, rbx
    add r8, %1
    cmp r8, -1 ; if i == -1
    jne %%.not_left_most
    mov r8, r13 ; i = size[ROWS] - 1
    sub r8, 1

%%.not_left_most:
    add r9, %2
    cmp r9, -1
    jne %%.not_top_most
    mov r9, r14
    sub r9, 1

%%.not_top_most:
    cmp r8, r13
    jne %%.not_right_most
    xor r8, r8

%%.not_right_most:
    cmp r9, r14
    jne %%.not_bottom_most
    xor r9, r9

%%.not_bottom_most:
    get_board_cell rsi, r8, r9, r11
    add rcx, r11
    
%endmacro

%macro swap_boards 0
    mov r11, [rsi]
    mov r12, [rdx]
    mov [rsi], r12
    mov [rdx], r11
%endmacro


_make_simulation:
    save_state
    xor rax, rax ; i = 0

    getsize_row r13d
    getsize_col r14d
    jmp .for_row_test
.for_row:
    xor rbx, rbx ; j = 0
    jmp .for_col_test
.for_col:
    xor rcx, rcx
   ; no_of_nbrs = 0
    nbr_from (-1), (-1)
    nbr_from (-1), 0
    nbr_from (-1), 1
    nbr_from 0, (-1)
    nbr_from 0, 1
    nbr_from 1, (-1)
    nbr_from 1, 0
    nbr_from 1, 1
    flip_cell

    inc rbx
.for_col_test:
    cmp rbx, r14
    jl .for_col

    inc rax
.for_row_test:
    cmp rax, r13
    jl .for_row
   
    swap_boards

    mov r8, [rsi]
    mov r9, [rdx]

    restore_state
    ret

