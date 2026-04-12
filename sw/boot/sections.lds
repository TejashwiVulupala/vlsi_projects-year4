/* sections.lds */
MEMORY
{
    ram (rwx) : ORIGIN = 0x00000000, LENGTH = 0x4000 /* 16 KB */
}

SECTIONS
{
    .text : {
        . = ALIGN(4);
        *(.text)
        *(.text*)
        . = ALIGN(4);
    } > ram

    .data : {
        . = ALIGN(4);
        *(.data)
        *(.data*)
        . = ALIGN(4);
    } > ram

    .bss : {
        . = ALIGN(4);
        *(.bss)
        *(.bss*)
        *(COMMON*)  /* Added wildcard to force recognition */
        . = ALIGN(4);
    } > ram
}