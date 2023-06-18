OUTPUT_FORMAT(elf32-i386)
SECTIONS {
	. = 0x7c00;
	.boot : {
	 	KEEP(*(.boot*))
        . = 0x7dfe;
        SHORT(0xaa55)	
	}

   . = 0x7e00;
    stage2_start = .;

    .text : {
		KEEP(*(.entry))
        *(.text)
    }

    .rodata : ALIGN(4K) {
         *(.rodata, .rodata.*)
    }

	.data : ALIGN(4K) {
		*(.data)
	}

	.bss : ALIGN(4K) {
		*(.bss)
	}

	.pad : {
		. = ALIGN(512);
	}


	stage2_end = .;
	stage2_size = stage2_end - stage2_start;
    stage2_sector_size = (stage2_size / 512);

	stack_start = ALIGN(4K);
    . += 0x1000;
    stack_end = ALIGN(4K);
}
