section .boot
extern stage2_start;
extern stage2_sector_size;
[bits 16]
entry:
	mov [BOOT_DRIVE], dl

	xor ax, ax
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov gs, ax
	mov fs, ax

	mov bx, STR
	call print_str
	call enable_a20
	call load_second_stage
	call switch_to_pm
	jmp $

load_second_stage:
	mov si, DAP
	mov dl, [BOOT_DRIVE]

	mov ah, 0x42
	int 0x13
	jc load_err
	ret


load_err:
	mov bx, LOAD_ERR_MSG
	call print_str
	jmp $


%include "boot_sector/print.asm"
%include "boot_sector/a20_line.asm"
%include "boot_sector/pm.asm"


STR:
	db "running stage1...", 0

A20_ENABLED:
	db "A20 Line is enabled", 0

A20_DISABLED:
	db "A20 Line is disabled", 0
	
LOAD_ERR_MSG:
	db "unable to load data from disk", 0

BOOT_DRIVE:
	db 0


DAP:
db 0x10
db 0x0
dw stage2_sector_size
dw stage2_start
dw 0
dd 0x1
dd 0x0
