gdt_start:
  dd 0x0
  dd 0x0

code16:
  dw 0xFFFF 
  dw 0x0
  db 0x0
  db 0b10011010 
  db 0b10001111 
  db 0x0 

data16:
  dw 0xFFFF 
  dw 0x0
  db 0x0
  db 0b10010010 
  db 0b10001111 
  db 0x0 

code32: 
	dw 0xffff ; Limit: bits 0-15 
	dw 0x0 ; Base: bits 0-15
	db 0x0 ; Base: bits 16-23
	db 10011010b ; 1st  flags, type flags
	db 11001111b ; 2nd flags, Limit: bites 16-19
	db 0x0 ; Base: bits 24-31
		
data32: 
	dw 0xffff
	dw 0x0 
	db 0x0
	db 10010010b
	db 11001111b
	db 0x0

gdt_end:


gdt_descr:
  dw gdt_end - gdt_start - 1
  dd gdt_start


CODE16_SEG equ code16 - gdt_start
DATA16_SEG equ data16 - gdt_start

CODE32_SEG equ code32 - gdt_start
DATA32_SEG equ data32 - gdt_start
