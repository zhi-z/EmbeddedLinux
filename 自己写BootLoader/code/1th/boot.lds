SECTIONS {
    . = 0x33f80000;  // 与最高地址相差512k，我们的程序不会超过512k足够用
    .text : { *(.text) }
    
    . = ALIGN(4);
    .rodata : {*(.rodata*)} 
    
    . = ALIGN(4);
    .data : { *(.data) }
    
    . = ALIGN(4);
    __bss_start = .;
    .bss : { *(.bss)  *(COMMON) }
    __bss_end = .;
}
