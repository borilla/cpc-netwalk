# build just the disk image
netwalk.dsk:
	rasm build/build.asm -Isrc -eo

# build with symbol file for winape emulator
winape:
	rasm build/build.asm -Isrc -eo -sw -os build/netwalk.sym

# build with symbol file for ACE-DL emulator
ace-dl:
	rasm build/build.asm -Isrc -eo -rasm -os build/netwalk.rasm
