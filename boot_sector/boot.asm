[org 0x7c00]  ; where the boot sector will be loaded in memory
STAGE2 equ 0x1000
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

	mov al, 15
	mov dh, 0x00
	mov ch, 0x00
	mov cl, 0x02 ; sector after bootsector

        mov ah, 0x02 ;  bios read sectors function
        int 0x13  ; disk access interrupt

	jc load_err
	cmp al, 15
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
