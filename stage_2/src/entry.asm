section .entry
global entry
extern main
entry:
        call main
        jmp $
        