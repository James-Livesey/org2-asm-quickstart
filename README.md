# Psion Organiser II assembly quickstart
Learn how to write your own datapack programs for the Psion Organiser II in 6303 assembly language!

## Prerequisites
To install the dependencies required for the toolchain, assembler and emulator, you will need to run:

```bash
sudo apt install wget python3 tcl libsdl2-dev qtbase5-dev qt5-qmake cmake
```

## Assembling
To assemble a program into the .OPK datapack format, run `./build.sh $FILE`, where `$FILE` is the file containing the code you want to assemble.

To assemble a program and start the emulator, run `./build.sh $FILE --test`. In Visual Studio Code, you can press <kbd>F5</kbd> to assemble and run the currently active file.