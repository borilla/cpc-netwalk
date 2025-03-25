maze.dsk:
	rasm build/build.asm -Isrc -eo -sw -sq -os build/maze.sym
	rasm build/build.asm -Isrc -eo -rasm -os build/maze.rasm
