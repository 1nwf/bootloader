build: 
	cd stage_2 && zig build bin
	cd boot_sector && make boot.bin
	cat boot_sector/boot.bin stage_2/stage2.bin > boot.bin

run: build
	qemu-system-i386  -fda boot.bin

clean:
	rm boot_sector/boot.bin
	rm boot.bin
	rm stage_2/stage2.bin
	rm -rf stage_2/zig-out stage_2/zig-cache