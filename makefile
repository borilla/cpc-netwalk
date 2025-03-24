maze.dsk: maze.bin
	rasm build/compile.asm -I. -eo

maze.bin:
	rasm src/start.asm -I. -ob build/maze.bin
