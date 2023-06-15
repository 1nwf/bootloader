; borrowed from https://github.com/limine-bootloader/limine/blob/trunk/common/lib/real.s2.asm_bios_ia32
global bios_int
bios_int:
    ; Self-modifying code: int $int_no
    mov al, [esp+4]
    mov [.int_no], al

    ; Save out_regs
    mov eax,  [esp+8]
    mov [.out_regs], eax

    ; Save in_regs
    mov eax,  [esp+12]
    mov [.in_regs], eax

    ; Save GDT in case BIOS overwrites it
    ; sgdt [.gdt]

    ; Save IDT
    ; sidt [.idt]

    ; Load BIOS IVT
    lidt [.rm_idt]

    ; Save non-scratch GPRs
    push ebx
    push esi
    push edi
    push ebp

    ; Jump to real mode
    jmp 0x08:.bits16
bits 16
  .bits16:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov eax, cr0
    and al, 0xfe
    mov cr0, eax
    jmp 0x00:.cszero

  .cszero:
    xor ax, ax
    mov ss, ax

    ; Load in_regs
    mov dword [ss:.esp], esp
    mov esp, dword [ss:.in_regs]
    pop gs
    pop fs
    pop es
    pop ds
    popfd
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    mov esp, dword [ss:.esp]

    sti

    ; Indirect interrupt call
    db 0xcd
  .int_no:
    db 0

    cli

    ; Load out_regs
    mov dword [ss:.esp], esp
    mov esp, dword [ss:.out_regs]
    lea esp, [esp + 10*4]
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    pushfd
    push ds
    push es
    push fs
    push gs
    mov esp, dword [ss:.esp]

    ; Restore GDT
    ; lgdt [ss:.gdt]

    ; Restore IDT
    ; lidt [ss:.idt]

    ; Jump back to pmode
    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp 0x18:.bits32

bits 32
  .bits32:
    mov ax, 0x20
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Restore non-scratch GPRs
    pop ebp
    pop edi
    pop esi
    pop ebx

    ; Exit
    ret

align 16
  .esp:      dd 0
  .out_regs: dd 0
  .in_regs:  dd 0
  .gdt:      dq 0
  .idt:      dq 0
  .rm_idt:   dw 0x3ff
             dd 0