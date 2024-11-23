.global _start
.p2align 2
_start:
    ldr x8, .
    // create stack x21=stack top
    movz x21, #0x5000, LSL #16
	mov sp, x21

    // x18 is reserved for uart.
    movz x18, #0x900, LSL #16

    // enable uart int
    mov w8, 0x18        // TXIM(5) | RXIM(4) (tx, rx interrupt mask)
    str w8, [x18, 0x38] // UARTIMSC (interrupt mask set clear)

    bl gic_irq_init
    bl virtio_init
    bl virtio_data_init

    adrp x0, version
    add x0, x0, :lo12:version
    bl _kprint

    // movz x0, #0x0400, LSL #16 // read dtb
    // mov x0, 0
    // bl _kprint_inf

cancel:
    mov w0, 0xd
    strb w0, [x18]

    .p2align 2
prompt:
    mov x19, sp // readline buf

readline:
    bl _kread2
    strb w0, [x18]
    strb w0, [x19], #1 // readbuf ptr
    cmp x0, #0x3
    beq cancel
    cmp x0, #0xd
    bne readline

    mov w8, #0xa
    strb w8, [x18]

    mov x8, sp
    sub x8, x19, x8     // read len

    // add x8, x8, #0x30   // print read len
    // strb w8, [x18]
    // mov w8, #0xa
    // strb w8, [x18]      // print newline

    ldrb w9, [sp]

    cmp w9, #0x70
    beq cmd_p

    cmp w9, #0x73
    beq cmd_s

    cmp w9, #0x50
    beq cmd_P

    cmp w9, #0x72
    beq cmd_r

    cmp w9, #0x77
    beq cmd_w

    cmp w9, #0x78
    beq cmd_x

    cmp w9, #0x65
    beq cmd_e
    cmp w9, #0x45
    beq cmd_E

// cmd not found
    mov w9, 0x3f
    strb w9, [x18]
    mov w9, 0xa
    strb w9, [x18]

    b prompt

cmd_p:
    mov x0, 0x8
    add x1, x21, 0x2
    bl _read_hex // mem addr at x0
    bl _kdump

    b prompt
cmd_s:
    mov x0, 0x8
    add x1, x21, 0x2
    bl _read_hex
    mov x2, x0

    mov x0, 0x8
    add x1, x21, 0xb
    bl _read_hex

    str w0, [x2]
    b prompt

cmd_P: // read 32 bytes at

    mov x0, 0x8
    add x1, x21, 0x2
    bl _read_hex // mem addr at x0
    bl _kdump2
    b prompt

cmd_r:
    mov x0, 0x2
    add x1, x21, 0x2
    bl _read_hex
    bl virtio_read
    b prompt

cmd_w:
    mov x0, 0x2
    add x1, x21, 0x2
    bl _read_hex
    bl virtio_write
    b prompt

cmd_x:  // execute
    mov x8, 0x5000
    movk x8, 0x5000, lsl 16
    blr x8
    b prompt

cmd_E:  // edit
    mov x8, 0x5000
    movk x8, 0x5000, lsl 16
    ldrh w0, [x8]   // w9: file size
    mov w1, 0x10
    bl _printx32_3
    mov w0, 0xa
    strb w0, [x18]

    b prompt

cmd_e:  // edit binary
    mov x0, 0x5000
    movk x0, 0x5000, lsl 16
    bl _bedit_start
    b prompt

shutdown:
    adrp x0, bye
    add x0, x0, :lo12:bye
    bl _kprint

	b .

version:
    .asciz "asos v0.0.1\n"
bye:
    .asciz "Bye~\n"

