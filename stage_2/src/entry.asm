section .entry
global entry
extern stack_end
extern main
entry:
        mov bp, stack_end
        mov sp, bp
        call main
        jmp $
        