section .boot
extern stage2_start;
extern stage2_sector_size;
[bits 16]
entry:
	mov bx, STR
	call print_str
	call load_second_stage
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


print:
        mov ah, 0x0e ;  set teletype mode 
        int 0x10  ; video display interrupt
        ret

; NOTE: string address must be passed to bx 
print_str:
        mov al, [bx]
        cmp al, 0
        je done
        call print
        inc bx
        call print_str
        done: 
		ret
 

STR:
	db "running stage1...", 0

LOAD_ERR_MSG:
	db "unable to load data from disk", 0

