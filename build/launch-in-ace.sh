#!/bin/bash

# Open built game in Ace-DL emulator
# Assumes Ace-DL is installed in a fixed location so is unlikely to work generally
cd "$(dirname "$0")"
~/Amstrad\ CPC/Emulators/AceDL/AceDL netwalk.rasm netwalk.dsk -autoRunFile 'netwalk.bin'
