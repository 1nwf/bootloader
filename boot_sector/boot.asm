[org 0x7c00]  ; where the boot sector will be loaded in memory
STAGE2 equ 0x1000
mov bp, 0x9000 ; set the stack 
mov sp, bp
mov bx, STR
call print_str
call load_second_stage
call STAGE2
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
	mov bx, STAGE2

	mov al, 30 ; number of sectors to read
	mov dh, 0x00 ; head number
	mov ch, 0x00 ; cylinder number
	mov cl, 0x02 ; sector number. 2 is the sector after the bootsector

        mov ah, 0x02 ;  bios read sectors function
        int 0x13  ; disk access interrupt

	jc load_err
	cmp al, 30 ; check that the number of sectors read matches our request
	jne load_err

        popa
	ret

load_err:
	mov bx, LOAD_ERR_MSG
	call print_str
	jmp $


%include  "print_str.asm"

STR:
	db "Hello!", 0

LOAD_ERR_MSG:
	db "unable to load data from disk", 0


; zero padding and magic bios number
times 510-($-$$) db 0
dw 0xaa55
