qemu-system-aarch64 -machine virt,gic-version=3 -cpu cortex-a72 -smp 1 -kernel kernel.elf -nographic -m 512M -echr 17 \
    -global virtio-mmio.force-legacy=false \
    -drive file=flash.img,if=none,format=raw,id=x0 \
    -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 \
    -d page,guest_errors,strace,trace:virtio_notify,trace:virtio_queue_notify,trace:virtio_notify_irqfd,trace:virtio_notify_irqfd_deferred_fn,trace:virtio_set_status,trace:virtio_mmio_read,trace:virtio_mmio_write_offset,trace:virtio_mmio_queue_write,trace:virtio_mmio_guest_page,trace:virtio_mmio_setting_irq,trace:virtqueue_alloc_element,trace:virtqueue_fill,trace:virtqueue_flush,trace:virtqueue_pop \
    $1 $2

#removed -d flags: int,cpu_reset,
