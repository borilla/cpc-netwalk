#!/bin/bash

# Open built game in WinAPE emulator
# Assumes WinAPE is set to run on through a specific configuration within bottles so is unlikely to work generally
flatpak run --command=bottles-cli com.usebottles.bottles run -p WinApe -b 'Win10' -- /A:netwalk.bin /SYM:'D:\Asm\\netwalk\\build\\netwalk.sym' 'D:\Asm\\netwalk\\build\\netwalk.dsk'
