#!/bin/bash

# Open built game in WinAPE emulator
# Assumes WinAPE is set to run on through a specific configuration within bottles so is unlikely to work generally
flatpak run --command=bottles-cli com.usebottles.bottles run -p WinApe -b 'Win10' -- /A:maze.bin /SYM:'D:\Asm\\maze\\build\\maze.sym' 'D:\Asm\\maze\\build\\maze.dsk'
