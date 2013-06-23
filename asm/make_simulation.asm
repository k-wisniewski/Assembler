; This version does not support periodic boundary conditions
; registers:
;   arguments:
;    rdi - int* size
;    rsi - Board** board
;    rdx - Board** copy
;   others:
;

section .data
fmt:
    db `>DEBUG: %d\n`, 0
fmt1:
    db `>DEBUG: ---------------------------------------\n`, 0

section .text
    global make_simulation
    global check_compatibility
    extern printf

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

%macro dbg_print 1
    pushallimusing
    sub rsp, 0x8 ; align stack for OS X
    lea rdi, [rel fmt]
    mov rsi, %1
    xor rax, rax
    call printf
    add rsp, 0x8
    popallimusing
%endmacro

%macro dbg_print1 0
    pushallimusing
    sub rsp, 0x8 ; align stack for OS X
    lea rdi, [rel fmt1]
    xor rax, rax
    call printf
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
    mov %1, 0x3c
%endmacro

%macro getsize_col 1
    mov %1, 0x32
%endmacro

%macro get_board_cell 4 ; get_board_cell(Board*, i, j)
    mov %4, [%1]
    add r14, 2
    imul %2, r14
    sub r14, 2
    add %4, %2
    mov %4, [%4 + %3]
    and %4, 0x1
%endmacro

%macro write_board_cell 1
    mov r12, [rdx]
    add r12, r15
    mov [r12 + rbx], %1
%endmacro

%macro nbr_from 2
; %1 - i
; %2 - j
;    i == -1
    mov r8, rax
    add r8, %1
    mov r9, rbx
    add r9, %2
    get_board_cell rdi, r8, r9, r11
    add rcx, r11
%endmacro

%macro flip_cell 0
    mov r15, rax
    ;dbg_print r15
    get_board_cell rdi, r15, rbx, r11
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
    ;dbg_print r11
    write_board_cell r11
    jmp %%.done_writing
%%.change_cell:
    not r11
    and r11, 0x1
    ;dbg_print r11
    write_board_cell r11
%%.done_writing:
%endmacro

%macro swap_boards 0
    mov r11, [rsi]
    mov r12, [rdi]
    mov [rsi], r12
    mov [rdi], r11
%endmacro


make_simulation:
    save_state
    mov rax, 1; i = 1

    getsize_row r13d
    getsize_col r14d
    jmp .for_row_test
.for_row:
    mov rbx, 1 ; j = 1
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
    jle .for_col

    inc rax
.for_row_test:
    cmp rax, r13
    jle .for_row
   
    swap_boards

    restore_state
    ret

check_compatibility:
    save_state

    mov eax, 1
    cpuid
    and edx, 0x40
    cmp edx, 0x40
    jne .sse_supported
    ; ssse3
    mov ebx, ecx
    and ebx, 0x800000
    cmp ebx, 0x800000
    jne .sse_supported
    ; sse3
    mov ebx, ecx
    and ebx, 0x80000000
    cmp ebx, 0x80000000
    jne .sse_supported
    mov ebx, ecx
    ; sse 4.1
    mov ebx, ecx
    and ebx, 0x2000
    cmp ebx, 0x2000
    jne .sse_supported
    ; sse 4.2
    mov ebx, ecx
    and ebx, 0x1000
    cmp ebx, 0x1000
    jne .sse_supported
    ; sse 4
    mov ebx, ecx
    and ebx, 0x4000000
    cmp ebx, 0x4000000
    jne .sse_supported
    ; avx
    mov ebx, ecx
    and ebx, 0x1000
    cmp ebx, 0x1000

    ; if not supported exit
    mov al, 1
    mov ebx, 0
    int 0x80

.sse_supported:
    restore_state
    ret
