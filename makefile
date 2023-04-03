DIR := $(shell pwd)
BOOTLOADER := $(DIR)/zig-out/bin/stage2.bin

run: 
	zig build
	qemu-system-i386  -fda $(BOOTLOADER)

clean:
	rm boot.o
	rm entry.o
	rm -rf zig-out zig-cache