netwalk.dsk:
	rasm build/build.asm -Isrc -eo -sw -sq -os build/netwalk.sym
	rasm build/build.asm -Isrc -eo -rasm -os build/netwalk.rasm
