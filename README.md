# asos

alvin's simple operating system

targets 'virt' machine type on QEMU

## available commands

`p <addr: u32>` : poke. dump 0x10 bytes at address `addr`

`s <addr: u32, value: u32>` : scan. write `value` at address `addr`

`r <sector: u8>` : read from a sector and write to addr 0x50005000

`w <sector: u8>` : write to a sector from addr 0x50005000

`x` : execute code beginning from addr 0x50005000

`e <addr: u32>` : enter edit mode at addr 0x50005000

^c(end of text) to discard command currently typing

^m(carrage return) to send command

## edit mode commands

* word = 32 bytes

`q` : exit edit mode

`p` : print current 0x10 bytes at current address

`w` : go foward a word.

`b` : go back a word.

`W` : go foward a doubleword.

`B` : go back a doubleword.

`j` : go foward a quadword.

`k` : go back a quadword.


`r` : enter hexadecimal replace mode. replaces a word.

`R` : enter binary replace mode. replaces a word.

in replace mode: ^f and ^b to move foward and back.
