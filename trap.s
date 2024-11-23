    .balign 0x800
traps:
            // # current el w/ SP_EL0 //

    // sync. except., excl. ext. aborts
    b .

    // irq
    .balign 0x80
    b .

    // fiq
    .balign 0x80
    b .

    // serror, sync. ext. aborts, EASE==1
    .balign 0x80
    b .

            // current el w/ SP_ELx, x > 0 //

    // sync. except., excl. ext. aborts
    .balign 0x80
    b elxsync

    // irq
    .balign 0x80
    b elxirq

    // // fiq
    // .balign 0x80
    // b .

    // // serror, sync. ext. aborts, EASE==1
    // .balign 0x80
    // b .


            // // lower el, aarc64

    // // sync. except., excl. ext. aborts
    // .balign 0x80
    // b .

    // // irq
    // .balign 0x80
    // b .

    // // fiq
    // .balign 0x80
    // b .

    // // serror, sync. ext. aborts, EASE==1
    // .balign 0x80
    // b .



            // // lower el, aarc32

    // // sync. except., excl. ext. aborts
    // .balign 0x80
    // b .

    // // irq
    // .balign 0x80
    // b .

    // // fiq
    // .balign 0x80
    // b .

    // // serror, sync. ext. aborts, EASE==1
    // .balign 0x80
    // b .


    .p2align 2
elxsync:
    str x0, [sp, -0x10]!

    adrp x0, s_exception
    add x0, x0, :lo12:s_exception
    bl _kprint
    mov x0, 0x21    // !
    str x0, [x18]
    ldr x0, [sp], 0x10

    b .
    eret

    .p2align 2
elxirq:
    str x0, [sp, -0x10]!

    mrs x0, icc_iar1_el1
    // add x0, x0, 0x30
    // str x0, [x18]

    mov w8, 0x18
    strb w8, [x18, 0x44]

    msr icc_eoir1_el1, x0

    ldr x0, [sp], 0x10
    eret

    .p2align 2
elxfiq:
    str x0, [sp, -0x10]!
    mov x0, 0x28    // '
    str x0, [x18]
    // ldr x0, =_start
    // msr elr_el1, x0
    ldr x0, [sp], 0x10
    b .
    eret

    .p2align 2
gic_irq_init:
    adrp x8, traps
    add x8, x8, :lo12:traps
    msr VBAR_EL1, x8

    // gic init
    movz X1, 0x800, lsl #16 // x1: GIC PERPHERAL BASE
    str wzr, [x1] // GICD_CTLR

    ldr w8, [x1, 0x4]   // GICD_TYPR, type reg
    and w8, w8, 0x1f    // count of lines (should be 8)

    mov w9, 1           // hard coded lines init
    neg w9, w9
    str w9, [x1, 0x80]  // GICD_GROUPR0
    str w9, [x1, 0x84]  // GICD_GROUPR1
    str w9, [x1, 0x88]  // GICD_GROUPR2
    str w9, [x1, 0x8c]  // GICD_GROUPR3
    str w9, [x1, 0x90]  // GICD_GROUPR4
    str w9, [x1, 0x94]  // GICD_GROUPR5
    str w9, [x1, 0x98]  // GICD_GROUPR6
    str w9, [x1, 0x9c]  // GICD_GROUPR7

    // enable interrupt for
    // uart0_irq: 0x21(33), virtio0_irq: 0x30(48)
    ldr w8, [x1, 0x104] // GICD_ISENABLER(0x30 / 0x20 * 4), interrupt set enable registers
    // movz w9, 0x1, LSL 16    // is(interrupt set) 0x30 % 0x20
    // orr w8, w8, w9
    orr w8, w8, 0x2
    str w8, [x1, 0x104] // to enable

    // giccinit

    msr icc_igrpen1_el1, xzr
    mov x8, 0xff
    msr icc_pmr_el1, x8     // proiority mask register el1

    mov w8, 2
    str w8, [x1]            // GICD_CTLR (enable secure groupd 1 interrupts)
    mov x8, 1
    msr icc_igrpen1_el1, x8 // interrupt group 1 enable el1
    msr DAIF, xzr           // clear interrupt mask (is set on reset)

    ret

s_exception:
    .asciz "exception occured"
