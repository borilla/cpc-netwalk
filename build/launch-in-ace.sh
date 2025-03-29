#!/bin/bash

# attempt to run makefile in the dev container [Does nothing if container isn't running]
docker ps | grep vsc-netwalk | awk '{print $1}' | head -1 | xargs -i docker exec {} make --directory /workspaces/netwalk ace-dl

# cd to build directory
cd "$(dirname "$0")"

# open and run disk image in Ace-DL emulator [Assumes Ace-DL is installed in a fixed location so is unlikely to work generally]
~/Amstrad\ CPC/Emulators/AceDL/AceDL netwalk.rasm netwalk.dsk -autoRunFile 'netwalk'
