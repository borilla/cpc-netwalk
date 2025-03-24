maze.dsk: maze.bin
	rasm build/compile.asm -eo

maze.bin:
	rasm start.asm -Isrc -ob build/maze.bin
