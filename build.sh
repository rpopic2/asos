aarch64-elf-as main.s io.s virtio.s e.s trap.s -o main.o \
&& aarch64-elf-ld -nostdlib -T linker.ld -z max-page-size=0x04 main.o -o kernel.elf

