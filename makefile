build: 
	cd stage_2 && zig build bin
	cd boot_sector && make boot.bin
	cat boot_sector/boot.bin stage_2/stage2.bin > os-image.bin

run: build
	qemu-system-i386  -fda os-image.bin

clean:
	rm boot_sector/boot.bin
	rm os-image.bin
	rm stage_2/stage2.bin
	rm -rf stage_2/zig-out stage_2/zig-cache