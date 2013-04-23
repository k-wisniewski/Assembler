; This version does not support periodic boundary conditions
; registers:
;   arguments:
;    rdi - int* size
;    rsi - Board*** board
;    rdx - Board*** copy
;   others:
;    rax - current row
;    rbx - current column offset
;    rcx - temp for SSE masks
;    r8, r9 - indexes of elements to fetch
;    r11 - address to load
;    r12 - address to store
;    r13 - size[ROW]
;    r14 - size[COL]
;

section .data
ptr_size:
    db 0x8
fmt:
    db `>DEBUG: %x\n`, 0
fmt_1_half:
    db `>DEBUG: %lld`, 0
fmt_2_half:
    db `>DEBUG: %lld\n`, 0

fmt1:
    db `>DEBUG: i %d\n`, 0
fmt2:
    db `>DEBUG: j %d\n`, 0

section .text
    global _make_simulation
    extern _printf

%macro pusha_used 0
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r11
    push r12
    push r13
    push r14
%endmacro

%macro popa_used 0
    pop r14
    pop r13
    pop r12
    pop r11
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
    pusha_used
    sub rsp, 0x8 ; align stack for OS X
    lea rdi, [rel %2]
    mov rsi, %1
    xor rax, rax
    call _printf
    add rsp, 0x8
    popa_used
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

%macro write_board_cell 1
    mov r12, [rdx]
    mov r12, [r12 + rax * 8]
    add r12, rbx
    movdqu [r12], %1
%endmacro

%macro load_middle_cell 0
    mov r11, [rsi]
    mov r11, [r11 + rax * 8]
    lddqu xmm9, [r11 + rbx]
%endmacro

%macro flip_cells 0
    movaps xmm10, xmm8
    movaps xmm11, xmm8

;    ;new = (old && sum == 2) || (sum == 3)
    pcmpeqb xmm10, xmm12
    pand xmm10, xmm9
    pcmpeqb xmm11, xmm13
    por xmm11, xmm10
    pand xmm11, xmm15

    write_board_cell xmm11
%endmacro

%macro nbr_from 3
; %1 - i
; %2 - j
    mov r8, rax
    mov r9, rbx
    add r8, %1
    add r9, %2

    mov r11, [rsi]
    mov r11, [r11 + r8 * 8]
    lddqu %3, [r11 + r9]
 
    paddb xmm8, %3

%endmacro

%macro swap_boards 0
    mov r11, [rsi]
    mov r12, [rdx]
    mov [rsi], r12
    mov [rdx], r11
%endmacro

%macro load_128_bit_consts 0
    mov rcx, 0x0202020202020202
    movq xmm12, rcx
    movlhps xmm12, xmm12
    mov rcx, 0x0303030303030303
    movq xmm13, rcx
    movlhps xmm13, xmm13
    mov rcx, 0x0101010101010101
    movq xmm15, rcx
    movlhps xmm15, xmm15
%endmacro

%macro first_iteration 0
    xorps xmm8, xmm8 ; no_of_nbrs = 0
    nbr_from 0, (-1), xmm3
    nbr_from 0, 1, xmm4
    nbr_from 1, (-1), xmm5
    nbr_from 1, 1, xmm7
    nbr_from 1, 0, xmm6
    nbr_from (-1), (-1), xmm0
    nbr_from (-1), 0, xmm1
    nbr_from (-1), 1, xmm2
    load_middle_cell
    flip_cells
%endmacro

%macro recycle_registers 0
    xorps xmm8, xmm8 ; no_of_nbrs = 0
    movaps xmm0, xmm3
    paddb xmm8, xmm0
    movaps xmm1, xmm9
    paddb xmm8, xmm1
    movaps xmm2, xmm4
    paddb xmm8, xmm2
    movaps xmm3, xmm5
    paddb xmm8, xmm3
    movaps xmm4, xmm7
    paddb xmm8, xmm4
    movaps xmm9, xmm6
%endmacro


_make_simulation:
    save_state

    load_128_bit_consts

    mov rbx, 1; j = 1

    getsize_row r13d
    getsize_col r14d

    jmp .for_col_test

.for_col:
    mov rax, 1; i = 1
    first_iteration
    inc rax
    jmp .for_row_test

.for_row:
    recycle_registers
    ; bottom row needs to be fetched
    nbr_from 1, (-1), xmm5
    nbr_from 1, 0, xmm6
    nbr_from 1, 1, xmm7
    flip_cells   
    inc rax

.for_row_test:
    cmp rax, r13
    jle .for_row

    add rbx, 16
.for_col_test:
    cmp rbx, r14
    jle .for_col

.after_main_loop:
    swap_boards

    mov r8, [rsi]
    mov r9, [rdx]

    restore_state
    ret

