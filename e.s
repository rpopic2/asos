// editor
    .p2align 2
_bedit_start:   // x0: start addr
    stp x30, x19, [sp, -0x10]!
    mov x19, x0 // x19: cur addr

    .p2align 2
__bedit_loop:
    bl _kread2
    cmp w0, 0x71
    beq __bedit_cmd_q
    cmp w0, 0x70
    beq __bedit_cmd_p
    cmp w0, 0x6a
    beq __bedit_cmd_j
    cmp w0, 0x6b
    beq __bedit_cmd_k
    cmp w0, 0x0d
    beq __bedit_cmd_cr

    cmp w0, 0x77
    beq __bedit_cmd_w
    cmp w0, 0x62
    beq __bedit_cmd_b
    cmp w0, 0x57
    beq __bedit_cmd_W
    cmp w0, 0x42
    beq __bedit_cmd_B

    cmp w0, 0x72
    beq __bedit_cmd_r
    cmp w0, 0x52
    beq __bedit_cmd_R
    cmp w0, 0x49
    beq __bedit_cmd_I

    cmp w0, 0x74
    beq __bedit_cmd_t
    cmp w0, 0x50
    beq __bedit_cmd_P

    mov w0, 0x3f
    strb w0, [x18]
    b __bedit_loop

__bedit_cmd_q:   // quit
    mov w0, 0xa
    strb w0, [x18]
    ldp x30, x19, [sp], 0x10
    ret

__bedit_cmd_p:   // print current 0x10
    mov w0, 0xa
    strb w0, [x18]
    mov x0, x19
    bl _kdump
    b __bedit_loop

__bedit_cmd_j:
    add x19, x19, 0x10
    b __bedit_cmd_p
__bedit_cmd_k:
    sub x19, x19, 0x10
    b __bedit_cmd_p
__bedit_cmd_cr:
    bic x19, x19, 0xf
    b __bedit_mov_head

__bedit_mov_head:
    mov w8, 0x8
    strb w8, [x18]
    and w0, w19, 0xf
    add w0, w0, 0x30
    mov w9, 0x27
    cmp w0, 0x39
    csel w9, w9, wzr, gt
    add w0, w0, w9
    strb w0, [x18]
    b __bedit_loop

__bedit_cmd_w:
    add x19, x19, 0x4
    b __bedit_mov_head

__bedit_cmd_b:
    sub x19, x19, 0x4
    b __bedit_mov_head

__bedit_cmd_W:
    add x19, x19, 0x8
    b __bedit_mov_head

__bedit_cmd_B:
    sub x19, x19, 0x8
    b __bedit_mov_head

__bedit_cmd_r:
    mov w8, 0x20
    str w8, [x18]
    // print out 32 bytes
    ldr w20, [x19]
    // mov w0, 0x123
    mov w2, 0x20
    mov w1, 0x8
    mov w21, 0x4

__bedit_cmd_r_loop_2: // print out current word
    mov w0, w20
    bl _printx32_3
    strb w2, [x18]  // print out space
    asr w20, w20, 0x8
    sub w21, w21, 0x1
    cmp w21, 0x0
    bgt __bedit_cmd_r_loop_2

    // csi sequence to move cursor back
    mov w8, 0x1b
    strb w8, [x18]
    mov w8, 0x5b
    strb w8, [x18]
    mov w0, 0x31
    strb w0, [x18]
    mov w0, 0x32
    strb w0, [x18]
    mov w0, 0x44
    strb w0, [x18]

     // read and write
    ldr w0, [x19]
    mov w3, 0x30    // const, sub if num
    mov w4, 0x57    // const, sub if alph
    // mov w0, 0xd
    // strb w0, [x18]
    mov w2, 0x3
    mov x20, x19
__bedit_cmd_r_loop:
    bl _kread2
    strb w0, [x18]
    cmp w0, 0x60
    csel w1, w3, w4, lt
    sub w5, w0, w1  // w5: first digit
    lsl w5, w5, 0x4
    cmp w5, 0x0
    bmi __bedit_cmd_r_cancel

    bl _kread2
    strb w0, [x18]
    cmp w0, 0x60
    csel w1, w3, w4, lt
    sub w0, w0, w1
    add w0, w0, w5

    cmp w0, 0x0
    bmi __bedit_cmd_r_cancel

    strb w0, [x20], #1  // ptr++
    mov w0, 0x20        // print space
    strb w0, [x18]
    subs w2, w2, 0x1
    bpl __bedit_cmd_r_loop

    mov w0, 0x9 //htab
    strb w0, [x18]
    add x19, x19, 0x4
    b __bedit_mov_head

__bedit_cmd_r_cancel:
    mov w0, 0xa
    strb w0, [x18]
    b __bedit_loop

__bedit_cmd_I:      // replace as binary
    // print out a word as binary (32 bits)
    mov w20, 0x30   // const w20: '0'
    mov w21, 0x31   // const w21: '1'
    mov w22, 0x20   // const w22: space
    mov w9, 0x20    // w9: counter
    ldr w13, [x19]   // x0: number
    rbit w0, w13

__bedit_cmd_I_loop:
    ands w8, w9, 0x7 // test lower 3 bits
    csel w1, w22, wzr, eq
    strb w1, [x18]

    ands w8, w0, 0x1
    csel w1, w20, w21, eq
    // cinc w1, w20, eq
    strb w1, [x18]

    asr w0, w0, 0x1
    subs w9, w9, 0x1
    bne __bedit_cmd_I_loop

    mov w8, 0x1b
    strb w8, [x18]
    mov w8, 0x5b
    strb w8, [x18]
    mov w0, 0x33
    strb w0, [x18]
    mov w0, 0x36
    strb w0, [x18]
    mov w0, 0x44
    strb w0, [x18]

    mov w23, 0x1        // const w23: 1
    mov w24, 0x20       // w24: counter
    mov w2, 0x20        // w2: acc
__bedit_cmd_I_loop2:    // replace 0s and 1s
    ands w8, w24, 0x7   // test lower 3 bits
    csel w1, w22, wzr, eq   // print space to improve readability
    strb w1, [x18]

    bl _kread2
    cmp w0, 0x1b // escape
    beq __bedit_cmd_I_cancel

    cmp w0, 0x30
    csel w0, wzr, w23, le
    // cinc w0, wzr, gt
    lsl w2, w2, 0x1
    add w2, w2, w0
    add w1, w0, 0x30
    strb w1, [x18]

    subs w24, w24, 0x1
    bne __bedit_cmd_I_loop2

__bedit_cmd_I_end:
    str w2, [x19], 0x4
    b __bedit_mov_head

__bedit_cmd_I_cancel:
    mov w0, 0xa
    strb w0, [x18]
    b __bedit_mov_head

__bedit_cmd_R:
    ldr w10, [x19]  // w10: word to edit
    movz w1, 0x8000, lsl 16 // w1: bit to test
    mov w2, 0x30    // w2: '0'
    mov w3, 0x20    // w3: counter
    mov w4, 0x20    // w4: ' '

__bedit_cmd_R_loop:
    tst w3, 0x3             // print space every four digits
    csel w8, w4, wzr, eq
    strb w8, [x18]
    tst w10, w1             // test bit and print '0' or '1'
    cinc w8, w2, ne
    strb w8, [x18]
    lsr w1, w1, 0x1
    subs w3, w3, 0x1
    bne __bedit_cmd_R_loop

    mov w0, 0x33           // move cursor to start position
    mov w1, 0x39
    bl _csi_xx

    movz w2, 0x8000, lsl 16 // w2: bit to test
    mov w3, 0x20            // w3: counter

__bedit_cmd_R_loop2:
    bl _kread2
    strb w0, [x18]
    cmp w0, 0x30
    beq __bedit_cmd_R_0
    cmp w0, 0x31
    beq __bedit_cmd_R_1
    cmp w0, 0x6
    beq __bedit_cmd_R_ctrlf
    cmp w0, 0x2
    beq __bedit_cmd_R_ctrlb
    cmp w0, 0x20
    beq __bedit_cmd_R_loop2

    mov w0, 0xa         // exit
    strb w0, [x18]
    mov w2, 0x0
    b __bedit_cmd_R_cont

__bedit_cmd_R_ctrlf:
    mov w0, 0x31
    mov w1, 0x43
    bl _csi
    b __bedit_cmd_R_cont

__bedit_cmd_R_ctrlb:
    mov w0, 0x31
    mov w1, 0x44
    bl _csi
    lsl w2, w2, 0x1
    tst w3, 0x3             // print space every four digits
    add w3, w3, 0x1
    bne __bedit_cmd_R_loop2
    bl _csi
    b __bedit_cmd_R_loop2

__bedit_cmd_R_0:
    bic w10, w10, w2
    b __bedit_cmd_R_cont
__bedit_cmd_R_1:
    orr w10, w10, w2
__bedit_cmd_R_cont:
    sub w3, w3, 0x1
    tst w3, 0x3             // print space every four digits
    csel w8, w4, wzr, eq
    strb w8, [x18]
    lsr w2, w2, 0x1
    cmp w2, 0x0
    bne __bedit_cmd_R_loop2

    str w10, [x19]
    b __bedit_loop


__bedit_cmd_t:
    strb w0, [x18]
    bl _kread2
    cmp w0, 0x1b    // escape on esc
    beq __bedit_loop
    strb w0, [x18]
    strb w0, [x19], 0x1
    b __bedit_cmd_t
__bedit_cmd_P:      // print as ascii
    mov w0, 0xa
    strb w0, [x18]
    bic x19, x19, 0xf
    mov w8, 0x0     // w8: counter
    mov w2, 0x2e    // w2: '.'
__bedit_cmd_P_loop:
    ldrb w9, [x19, x8]
    cmp w9, 0x20
    csel w9, w2, w9, lt
    strb w9, [x18]
    add w8, w8, 0x1
    cmp w8, 0xf
    ble __bedit_cmd_P_loop
    b __bedit_loop
