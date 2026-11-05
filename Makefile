run:
	nasm -f bin snake.asm -o snake.bin
	qemu-img create -f raw snake.img 512
	dd if=snake.bin of=snake.img
	qemu-system-i386 -drive file=snake.img,format=raw