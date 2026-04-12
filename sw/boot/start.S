.section .text.start
.global _start
_start:
    li sp, 0x3FFC    /* Top of 16KB RAM */
    call main
_halt:
    ebreak           /* Signal end to TB */
    j _halt