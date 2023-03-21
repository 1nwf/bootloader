[org 0x7c00]  ; where the boot sector will be loaded in memory
mov bx, STR
call print_str
jmp $

%include  "print_str.asm"

STR:
	db "Hello!", 0


; zero padding and magic bios number
times 510-($-$$) db 0
dw 0xaa55
