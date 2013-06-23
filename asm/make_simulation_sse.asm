; This version does not support periodic boundary conditions
; registers:
;   arguments:
;    rdi - Board*** board
;    rsi - Board*** copy
;   others:
;    rax - current row
;    rbx - current column offset
;    rcx - temp for SSE masks
;    r8, r9 - indexes of elements to fetch
;    r11 - address to load
;    r12 - address to store
;    r13 - BOARD_HEIGHT
;    r14 - BOARD_WIDTH
;

section .data
fmt:
    db `>DEBUG: %x\n`, 0

section .text
    global make_simulation
    global check_compatibility
    extern printf
;
; MACROS
;

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

%macro dbg_print 1
    pusha_used
    sub rsp, 0x8 ; align stack for OS X
    lea rdi, [rel fmt]
    mov rsi, %1
    xor rax, rax
    call printf
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

%macro write_board_cell 1
    mov r12, [rsi]
    mov r15, r14
    add r15, 0x11
    imul r15, rax
    add r12, r15
    movdqu [r12 + rbx], %1
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
    mov r11, [rdi]
    mov r8, r14
    add r8, 0x11
    mov r9, rax
    add r9, %1 
    imul r8, r9
    add r11, r8
    mov r9, rbx
    add r9, %2
    lddqu %3, [r11 + r9]
    paddb xmm8, %3
%endmacro

%macro swap_boards 0
    mov r11, [rsi]
    mov r12, [rdi]
    mov [rsi], r12
    mov [rdi], r11
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
    ;xorps xmm1, xmm1 ; no_of_nbrs = 0
    ;xorps xmm2, xmm2 ; no_of_nbrs = 0
    ;xorps xmm3, xmm3 ; no_of_nbrs = 0
    ;xorps xmm4, xmm4 ; no_of_nbrs = 0
    ;xorps xmm5, xmm5 ; no_of_nbrs = 0
    ;xorps xmm6, xmm6 ; no_of_nbrs = 0
    ;xorps xmm7, xmm7 ; no_of_nbrs = 0
    xorps xmm8, xmm8 ; no_of_nbrs = 0
    xorps xmm9, xmm9 ; no_of_nbrs = 0

    nbr_from 0, (-1), xmm3
    nbr_from 0, 1, xmm4
    nbr_from 1, (-1), xmm5
    nbr_from 1, 1, xmm7
    nbr_from 1, 0, xmm6
    nbr_from (-1), (-1), xmm0
    nbr_from (-1), 0, xmm1
    nbr_from (-1), 1, xmm2
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

;
; ACTUAL FUNCTIONS
;

make_simulation:
    save_state

    load_128_bit_consts

    mov rbx, 1; j = 1
    
    ; size of board
    mov r13d, 0x3c
    mov r14d, 0x32

    jmp .for_col_test

.for_col:
    mov rax, 1; i = 1
    ; at the beginning of each column we need to fetch all neighbors
    first_iteration
    inc rax
    jmp .for_row_test

.for_row:
    recycle_registers
    ; only bottom row needs to be fetched
    nbr_from 1, (-1), xmm5
    nbr_from 1, 0, xmm6
    nbr_from 1, 1, xmm7
    flip_cells
    inc rax

.for_row_test:
    cmp rax, r13
    jle .for_row

    add rbx, 0x10
.for_col_test:
    cmp rbx, r14
    jle .for_col

.after_main_loop:
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
