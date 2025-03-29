#!/bin/bash

# attempt to run makefile in the dev container [Does nothing if container isn't running]
docker ps | grep vsc-netwalk | awk '{print $1}' | head -1 | xargs -i docker exec {} make --directory /workspaces/netwalk winape

# cd to build directory
cd "$(dirname "$0")"

# open and run disk image in WinAPE emulator [Assumes WinAPE is set to run on through a specific configuration within bottles so is unlikely to work generally]
flatpak run --command=bottles-cli com.usebottles.bottles run -p WinApe -b 'Win10' -- /A:netwalk /SYM:'D:\Asm\\netwalk\\build\\netwalk.sym' 'D:\Asm\\netwalk\\build\\netwalk.dsk'
