disable_a20:
        mov ax, 0x2400
        int 0x15
        ret

; returns 0 if disabled. 1 if enabled. return value placed in ax.
test_a20:
	push bx
	mov bx, 0xffff
	mov es, bx
	pop bx

	mov eax, [es:0x7e0e]
	cmp eax, 0xaa55

        je disabled

        ; check again
        mov al,  [es:0x7e0f]
        cmp al, 0xaa

        jne enabled
        disabled:
                mov ax, 0
                jmp exit
	enabled:
                mov ax, 1
        exit:
        	xor bx, bx
        	mov es, bx
                ret



enable_a20:
        ; bios method
        mov ax, 0x2401
        int 0x15
        call test_a20
        cmp ax, 1
        je success
        ret
        success:
                mov bx, A20_ENABLED
                call print_str
        	ret

