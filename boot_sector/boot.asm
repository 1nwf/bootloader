section .boot
extern stage2_start;
extern stage2_sector_size;
[bits 16]
entry:
	mov [BOOT_DRIVE], dl
	mov bx, STR
	call print_str
	call enable_a20
	call load_second_stage
	push dx
	call stage2_start
	jmp $

; al = number of sectors to read 
; dl = drive to read
; dh = head
; ch = cylinder 
; cl = sector
; bx = the address the data will be loaded into in memory
; https://en.wikipedia.org/wiki/INT_13H
load_second_stage:
        pusha
	mov dl, [BOOT_DRIVE]
	mov bx, stage2_start
	mov al, stage2_sector_size ; number of sectors to read
	mov dh, 0x00 ; head number
	mov ch, 0x00 ; cylinder number
	mov cl, 0x02 ; sector number. 2 is the sector after the bootsector

        mov ah, 0x02 ;  bios read sectors function
        int 0x13  ; disk access interrupt

	jc load_err
	cmp al, stage2_sector_size ; check that the number of sectors read matches our request
	jne load_err

        popa
	ret

load_err:
	mov bx, LOAD_ERR_MSG
	call print_str
	jmp $


%include "boot_sector/print.asm"
%include "boot_sector/a20_line.asm"


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

