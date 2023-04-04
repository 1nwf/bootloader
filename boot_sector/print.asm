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
