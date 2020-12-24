objects = mbr.o 
#boot.o

%.o: %.asm
	as -o $@ $<
	
boot.bin: $(objects) 
#ld $(objects) --oformat=binary -o $@ -T $<
#ld $(objects) --oformat=binary -o $@ -T $<
	ld -Ttext 0x7c00 -o $@ $(objects) --oformat binary
boot.img: boot.bin
	dd if=/dev/zero of=os.img bs=512 count=2880
	dd if=boot.bin of=boot.img bs=512 count=1
	dd if=os.img of=boot.img skip=1 seek=1 bs=512 count=2879

bochs: boot.img
	if [ ! -e .bochsrc ]; then ln -s bochsrc .bochsrc; fi
	bochs 
	#-q

qemu: boot.bin
	qemu-system-i386 -fda $< -boot a -monitor stdio

clean: 
	rm -f ./*.o ./*.bin ./*.img