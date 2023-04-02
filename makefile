DIR := $(shell pwd)
BOOTLOADER := $(DIR)/stage_2/zig-out/bin/stage2.bin
build: 
	zig build --build-file $(DIR)/stage_2/build.zig

run: build
	qemu-system-i386  -fda $(BOOTLOADER)

clean:
	rm stage_2/boot.o
	rm stage_2/entry.o
	rm -rf stage_2/zig-out stage_2/zig-cache