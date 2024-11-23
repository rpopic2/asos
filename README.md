# asos

alvin's simple operating system

targets 'virt' machine type on QEMU

## available commands

`p <addr: u32>` : poke. dump 0x10 bytes of at address `addr`
`s <addr: u32, value: u32>` : scan. write `value` at address `addr`
`r <addr: u32, sector: u8>` : read from a sector and write to addr
`w <addr: u32, sector: u8>` : write to a sector from addr
`x <addr: u32>` : execute code beginning from addr

`e <addr: u32>` : enter edit mode

^c(end of text) to discard command currently typing
^m(carrage return) to send command

