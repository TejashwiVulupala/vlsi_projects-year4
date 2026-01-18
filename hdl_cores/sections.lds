MEMORY {
    mem : ORIGIN = 0x00000000, LENGTH = 0x00004000
}

SECTIONS {
    . = 0x00000000;
    .text : { *(.text) } > mem
    .rodata : { *(.rodata*) } > mem
    .data : { *(.data) } > mem
    .bss  : { *(.bss)  } > mem
}