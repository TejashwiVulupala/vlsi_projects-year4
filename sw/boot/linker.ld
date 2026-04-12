ENTRY(_start)
MEMORY { RAM (xrw) : ORIGIN = 0x00000000, LENGTH = 0x4000 }
SECTIONS {
    .text : { . = ALIGN(4); *(.text.init) *(.text*) . = ALIGN(4); } > RAM
    .data : { . = ALIGN(4); *(.data*); . = ALIGN(4); } > RAM
    .bss  : { . = ALIGN(4); *(.bss*);  . = ALIGN(4); } > RAM
}