boot.bin:
	nasm -f bin boot.asm -o boot.bin

qemu: boot.bin
	qemu-system-i386  -fda boot.bin