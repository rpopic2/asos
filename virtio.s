    // ref: xv6-riscv virtio_disk.c
    .p2align 2
virtio_init:
    str x30, [sp, -0x10]!

    // virtio init

    mov w3, 0x30                 // w3: progress code

    mov w2, 0x0                 // w2: status
    movz x1, 0x0a00, lsl #16    // x1: virtio_mmio_base

    ldr w8, [x1]                // load magic
    movz w9, 0x7472, lsl #16    // magic high
    mov w10, 0x6976             // magic low
    add w9, w9, w10             // magic
    cmp w8, w9
    bne virtio_init_err
    mov w3, 0x31

    ldr w8, [x1, 0x4]   // load version
    mov w9, 0x2         // virtio version
    cmp w8, w9
    bne virtio_init_err
    mov w3, 0x32

    ldr w8, [x1, 0x8]   // load device id
    cmp w8, w9
    bne virtio_init_err
    mov w3, 0x33

    ldr w8, [x1, 0xc]           // load vendor id
    movz w9, 0x554d, lsl #16    // vendor id high
    mov w10, 0x4551             // vendor id low
    add w9, w9, w10             // vendor id
    cmp w8, w9
    bne virtio_init_err
    mov w3, 0x34

    str w2, [x1, 0x70]  // reset device (0 to status)
    orr w2, w2, 0x1     // status ack
    str w2, [x1, 0x70]  // update status

    orr w2, w2, 0x2     // status config_s_driver
    str w2, [x1, 0x70]  // update status

    ldr w8, [x1, 0x10]  // read dEvice features
    mov w9, 0x6654      // just going to hard-code feature for now
    str w9, [x1, 0x20]  // write dRiver features

    orr w2, w2, 0x8     // status features ok
    str w2, [x1, 0x70]

    ldr w2, [x1, 0x70]
    tbz w2, 0x3, virtio_init_err // check if features are okay for the device
    mov w3, 0x35

    str wzr, [x1, 0x30]  // select q zero

    ldr w8, [x1, 0x44]              // q ready?
    tbnz w8, 0x0, virtio_init_err   // q should not be ready
    mov w3, 0x36

    ldr w8, [x1, 0x34]              // get queue_num_max
    cbz w8, virtio_init_err         // device has no queue
    add w3, w3, 0x37
    cmp w8, 0x8
    blt virtio_init_err             // queue is too small (lt 8)
    mov w3, 0x38

    mov w8, 0x8         // queue size (8)
    str w8, [x1, 0x38]  // set queue num

    // queue_desc at 0x50001000
    mov w8, 0x1000
    movk w8, 0x5000, LSL #16
    str w8, [x1, 0x80]  // queue_desc low
    str wzr, [x1, 0x84] // queue_desc high

    // queue_avail (driver_ring) at 0x50002000
    add w8, w8, 0x80
    str w8, [x1, 0x90]  // queue_avail low
    str wzr, [x1, 0x94] // queue_avail high

    // queue_used (device_ring) at 0x50003000
    mov w8, 0x1100
    movk w8, 0x5000, LSL #16
    str w8, [x1, 0xa0]  // queue_used low
    str wzr, [x1, 0xa4] // queue_used high

    mov w8, 0x1
    str w8, [x1, 0x44]  // tell device that queue is ready

    orr w2, w2, 0x4
    str w2, [x1, 0x70]  // tell device that we're completely ready

    // init success
    // adrp x0, virtio_success_str
    // add x0, x0, :lo12:virtio_success_str
    // bl _kprint
    mov w0, 0x4F    // print O to indicate ok
    // strb w0, [x18]
    b virtio_init_end

virtio_init_err:
    adrp x0, virtio_fail_str
    add x0, x0, :lo12:virtio_fail_str
    bl _kprint
    mov w0, 0x58    // print X to indicate err
    strb w0, [x18]

virtio_init_end:
    // strb w3, [x18]  // print err code
    ldr x30, [sp], 0x10
    ret

    .p2align 2
virtio_data_init:
    // get virtq_desc ready
    mov x1, 0x4000     // x1: virtio_blk_req base addr @ 50004000
    movk x1, 0x5000, lsl 16
    sub x2, x1, 0x3000  // x2: virtq_desc base @ 50001000

    // virtq_desc 0 @ 50001000
    add x9, x1, 0x180   // addr of type/reserved/sector from virtio_blk_req
    str x9, [x2]        // @ 50001180 ->50001000

    mov w8, 0x10            // len is 0x10
    str w8, [x2, 0x8]       // ->50001008
    movz w8, 0x1, LSL #16   // next flag
    add w8, w8, 0x1         // next idx
    str w8, [x2, 0xc]       // ->5000100c

    // virtq_desc 1 @ 50001010
    add x9, x1, 0x1000   // addr of data buf from virtio_blk_req
    str x9, [x2, 0x10]  // @ 50005000 ->50001010

    mov w8, 0x400           // len is 0x400
    str w8, [x2, 0x18]      // ->50001018
    mov w8, 0x3             // flag. next | write. (if write, next)
    strh w8, [x2, 0x1c]     // ->5000101c
    mov w8, 0x2             // next idx
    strh w8, [x2, 0x1e]     // ->5000101e

    // virtq_desc 2 @ 50001020
    add x9, x1, 0x5a0   // addr of status byte of virtio_blk_req
    str x9, [x2, 0x20]  // @ 500015a0 ->50001020

    mov w8, 0x1             // len is 0x1
    str w8, [x2, 0x28]      // ->50001028
    mov w8, 0x2             // write flag, no next idx
    strh w8, [x2, 0x2c]     // ->5000102c

    // virtq_blk_req @50004180
    mov w8, 0x0         // in(0). (if req is write, out(1))
    str w8, [x1, 0x180] // ->50001180

    // data buf @50005000

    // status   @500045a0
    mov w8, 0xff
    mov x10, 0x5a0
    add x9, x1, x10
    strb w8, [x9]


    movz x8, 0x5000, LSL #16
    mov x9, 0x2000
    add x8, x8, x9      // x8: virtio_avail(driver ring) base @50002000

    str wzr, [x8, 0x8]  // write to [ring, 0x0]
    dmb ish
    ret

    .p2align 2
virtio_write:   // x0: sector
    mov x9, 0x4000
    movk x9, 0x5000, lsl 16
    // virtq_blk_req @50004180
    mov w8, 0x1         // in(0). (if req is write, out(1))
    // r: 0x0
    str w8, [x9, 0x180] // ->50004180
    str x0, [x9, 0x188]   // sector ->50004188

    sub x9, x9, 0x3000
    mov w8, 0x1             // flag. next | write. (if write, next)
    strh w8, [x9, 0x1c]     // ->5000101c
    // r: 0x3
    b virtio_notify

    .p2align 2
virtio_read:    // x0: sector
    mov x1, 0x4000
    movk x1, 0x5000, lsl 16
    // virtq_blk_req @50004180
    mov w8, 0x0         // in(0). (if req is write, out(1))
    str w8, [x1, 0x180] // ->50004180
    str x0, [x1, 0x188]   // sector ->50004188

    sub x9, x9, 0x3000
    mov w8, 0x3             // flag. next | write. (if write, next)
    strh w8, [x2, 0x1c]     // ->5000101c
    b virtio_notify

    .p2align 2
virtio_notify:
    // status   @500045a0
    mov x1, 0x45a0
    movk x1, 0x5000, lsl 16

    mov w8, 0xff
    strb w8, [x1]

    // avail_ring.idx @ 50001082
    mov x8, 0x1082
    movk x8, 0x5000, lsl 16

    ldrh w9, [x8]
    add w9, w9, 0x1     // inc idx
    strh w9, [x8]  // write to idx
    dmb ish

    movz x1, 0x0a00, lsl #16    // x1: virtio_mmio_base @0a000000
    str wzr, [x1, 0x50]         // virtio_mmio_queue_notify

    ret

virtio_fail_str:
    .asciz "virtio init failed\n"
virtio_success_str:
    .asciz "virtio init success\n"
