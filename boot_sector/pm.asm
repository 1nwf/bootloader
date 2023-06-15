extern stack_end;
switch_to_pm:
  cli
  lgdt [gdt_descr]
  mov eax, cr0
  or eax, 0x1
  mov cr0, eax
  jmp CODE32_SEG:init_pm

[bits 32]
init_pm: 
  ; set segment registers
  mov ax, DATA32_SEG

  mov ds, ax
  mov ss, ax
  mov es, ax
  mov fs, ax
  mov gs, ax

  ; set stack
  mov ebp, stack_end
  mov esp, ebp
  ; jump to second stage
  push edx
  jmp stage2_start

%include "boot_sector/gdt.asm"
