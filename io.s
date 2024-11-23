_write_at:
    movz x8, #0x5000, LSL #16
    str w0, [x8, 0x10]
    ret

_read_hex: // x0 count, x1 addr ->w0 ret. ascii to hex
    mov x8, x1
    mov x10, x0 // counter
    sub x10, x10, 0x1
    mov x11, 0x1 // factor
    mov x12, 0x10 // ten
    mov w0, 0x0 // ret val, acc
__read_hex_loop:
    cmp x10, 0x0
    blt __reg_hex_end
    ldrb w9, [x8, x10]

    cmp w9, 0x60
    ble __read_hex_num
    sub w9, w9, 0x57
    b __read_hex_continue
__read_hex_num:
    sub w9, w9, 0x30
__read_hex_continue:
    mul w9, w9, w11
    mul w11, w11, w12
    add w0, w0, w9
    sub x10, x10, 0x1
    b __read_hex_loop
__reg_hex_end:
    ret

_kdump2:
    str x30, [sp, -0x10]!
    str x0, [sp, 0x8] // x0 addr

    mov x1, 0x1c
    bl _printx32_2

    ldr x2, [sp, 0x8]

    mov w8, 0x20
    strb w8, [x18]
    strb w8, [x18]

    mov x4, x2 // addr to dump
    mov x3, 0x0 //counter

    ldr w0, [x4]
    mov x1, 0x1c
    bl _printx32_2

    mov w8, #0xa // newline and fin
    strb w8, [x18]
    ldr x30, [sp], 0x10
    ret


_kdump:
    str x30, [sp, -0x10]!
    str x0, [sp, 0x8]

    ldr x2, [sp, 0x8]

    asr x0, x2, 0x18
    bl _printx8
    asr x0, x2, 0x10
    bl _printx8
    asr x0, x2, 0x8
    bl _printx8
    mov x0, x2
    bl _printx8

    mov x12, x2
    mov x11, 0x0

    mov w8, 0x20
    strb w8, [x18]
    strb w8, [x18]
dumps:
    cmp x11, 0x10
    bge dumps_end
    add x11, x11, 0x1

    ldrb w0, [x12]
    bl _printx8
    mov w8, #0x20
    strb w8, [x18]
    add x12, x12, 0x1

    b dumps

dumps_end:
    mov w8, #0xa
    strb w8, [x18]
    ldr x30, [sp], 0x10
    ret


_printx32_3: // x0: num, x1: width->
    mov x8, x0 // target char
    // mov w10, 0x1c
    mov w10, w1
.p2align 2
__printx32_3_loop:
    subs w10, w10, 0x4
    bmi __printx32_3_ret
    asr x9, x8, x10
    and w9, w9, 0xf
    cmp w9, 0xa
    b.lt __printx32_3_num
    add w9, w9, 0x27
__printx32_3_num:
    add w9, w9, 0x30
    strb w9, [x18]
    b __printx32_3_loop
__printx32_3_ret:
    ret

_printx32_2: // x0: num, x1: width
    mov x8, x0 // target char
    // mov w10, 0x1c
    mov w10, w1

_printx32_2_loop:
    asr x9, x8, x10
    and w9, w9, 0xf
    cmp w9, 0xa
    blt _printx32_2_num
    add w9, w9, 0x27
_printx32_2_num:
    add w9, w9, 0x30
    strb w9, [x18]

    subs w10, w10, 0x4
    bpl _printx32_2_loop

    ret

// _print8:    // w0: target i8 ->
//     and w8, w0, 0xf
//     cmp w8, 0xa
//     mov w9, 0x27
//     csel w9, w9, wzr, ge
    // add w8, w9, 

_printx8: //prints out hex, single byte
    mov w8, w0 // target char

    asr w9, w8, 0x4
    and w9, w9, 0xf
    cmp w9, 0xa
    blt __printx8_num
    add w9, w9, 0x27
__printx8_num:
    add w9, w9, 0x30
    strb w9, [x18]

    and w9, w8, 0xf
    cmp w9, 0xa
    blt _printx8__foo
    add w9, w9, 0x27
_printx8__foo:
    add w9, w9, 0x30
    strb w9, [x18]

    ret


    .p2align 2
_kread2:    // =>w0: read a char
    wfi
    add x8, x18, 0x18
    ldrb w9, [x8]
    tbnz w9, #4, _kread2

    ldrb w0, [x18]
    ret

    .p2align 2
_kprint:
    ldrb w8, [x0], #1
    cbz w8, kprint_end
    str w8, [x18]
    b _kprint
kprint_end:
    ret

_kprint_inf:
    ldrb w10, [x0], #1
    str w10, [x18]
    b _kprint_inf

_csi:
    mov w8, 0x1b
    strb w8, [x18]
    mov w8, 0x5b
    strb w8, [x18]
    strb w0, [x18]
    strb w1, [x18]
    ret

_csi_xx:
    mov w8, 0x1b
    strb w8, [x18]
    mov w8, 0x5b
    strb w8, [x18]
    strb w0, [x18]
    strb w1, [x18]
    mov w0, 0x44
    strb w0, [x18]
    ret
