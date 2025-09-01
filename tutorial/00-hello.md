# Hello, Psion!
In this guide, you'll be learning how to write a simple application for the Organiser II that installs itself to the main menu and displays a message when selected.

In order to learn starting with the basics, we'll be starting from a blank file. The full code we'll be writing is available in [hello.asm](../hello.asm). Before we do anything, please ensure you have followed the instructions listed in the [prerequisites section of the readme](../readme.md#prerequisites).

## Foundational knowledge
For this tutorial, we'll assume that you have a basic understanding of how a CPU works, in terms of memory, registers, and addressing. The Organiser II isn't too different from other computers from the 80s — only just miniaturised, and with slightly less RAM. However, it's a different beast when compared to modern computers (and particularly smartphones) as it lacks several features, such as memory protection and a multitasking operating system.

The Organiser II's system software resides in read-only memory (ROM), which is memory-mapped alongside random access memory (RAM). This means that addressing is linear, but some of it points to ROM, and the rest to RAM. When the Organiser II boots up, it executes code from ROM, and the built-in apps reside there too; but when executing an application from a datapack, this code is loaded into RAM.

Since there is no memory protection, an application can write to anywhere in RAM. (However, it can't write to ROM, as ROM is read-only.) This means that if there is an addressing-related bug in your code, your code may end up overwriting RAM and corrupting it. Remember that aside from datapacks, the Organiser II uses RAM as its primary place to store files, so ensure that all your files are backed up before attempting to run your own code.

There may be times where your code causes the Organiser II to crash or get into an infinite loop, which means removing the battery. When you do this, you'll lose all the files stored in RAM. Even more reason to back up your files!

Luckily, the emulator — which we'll be using here for development purposes — is much less risky to experiment with.

## Let's get cracking
Create a new file in this repository, and give it a name that ends with `.asm`. Visual Studio Code is recommended here, as this repository is set up to enable you to press <kbd>F5</kbd> to easily run your code in an emulator.

Start your code with:

```asm
.INCLUDE MOSVARS.INC
.INCLUDE MOSHEAD.INC
.INCLUDE MSWI.INC

.ORG $241B-25
```

Here, we're first including a few files that provide us with common functionality that we'll then use to call system services. These files are provided by the assembler — think of this as importing header files for a standard library in C or C++.

`.ORG` tells the assembler what address offset to use when it comes to referencing labels in our code. We'll touch upon this more later.

## The datapack format
All datapacks must start with a header which tells the Organiser II the size of the datapack, among other details. Datapacks that contain applications must contain a special header so that the Organiser II can recognise that a datapack contains executable code, instead of being a general-purpose datapack.

This is what you'll need to use to add this header to your code:

```asm
xx:
	.BYTE	$6A		; Bootable
	.BYTE	$01		; Size 8K
	.BYTE	$00		; Code only
	.BYTE	$41		; Device number
	.BYTE	$10		; Version 1.0
	.BYTE	$41		; Priority
	.WORD	%root-%xx	; Device overlay address
	.BYTE	$FF
	.BYTE	$FF
	.BYTE	$09
	.BYTE	$81
	.ASCII	"MAIN    "
	.BYTE	$90
	.BYTE	$02
	.BYTE	$80
	.WORD	%prgend-%root	; Size of code
```

Each `.BYTE` tells the assembler to simply write a single byte to the final file we'll run, so that helps us to define our header. `.WORD` does the same, except it outputs a _word_ (two bytes) instead. `.ASCII` outputs a string. Here, we're not writing executable code yet — only raw data that the Organiser II will read when trying to load our program.

The first byte — `$6A` — tells the Organiser II that this datapck is bootable. All the rest of the bytes in the header more-or-less match what would be seen at the start of a general-purpose datapack.

## Writing our relocatable code
The Organiser II's operating system is very clever for its time — it allows you to have more than one application loaded into memory at once; up to three, in fact (corresponding to the two datapack slots, and the top slot connector, which acts as a special datapack slot).

To achieve this, the operating system may load applications _anywhere_ into memory, depending on what other applications are loaded. However, application code must be designed to allow the operating system to modify it so that all the absolute addresses can be 'fixed up' to reference data in wherever the application is loaded. This is achieved using Psion's relocatable format.

The actual magic happens when we get to `.OVER root`: this defines an _overlay_, called `root`. In practice, `.OVER` outputs some extra metadata that tells the Organiser II's operating system which bytes in the machine code to modify in order to ensure that all the addresses are 'fixed up' after the code is loaded from the datapack into RAM. An _overlay_ is essentially a single unit of code that is relocatable.

This is where the `.ORG` line from earlier comes in — the offset in use is sufficiently large (`$241B`) to ensure that all machine code instructions use addresses that are two bytes long, and thus are easily modifiable by the operating system.

To tie it all off, the `.WORD	%root-%xx` from earlier tells the Organiser II where it should expect the relocatable code to be in the datapack (`%root-%xx` refers to the number of bytes after the header), and `.WORD	%prgend-%root` tells the Organiser II how long that code is so that it can copy it to RAM.

Before we forget, add the following to the bottom of your code, to close off the `root` overlay and mark the end of the program:

```asm
.EOVER

.OVER prgend
.EOVER
```

From here on, you'll be writing code above this.

## Actually getting it to say something
Under `.OVER root`, add this:

```asm
start:
	.WORD	$0000
	.BYTE	$00
	.BYTE	$41		; Device number
	.BYTE	$10		; Version 1.0
	.BYTE	(endvec-vec)/2	; Number of vectors
```

This is the very first part of our application code that resides within our `root` overlay. This is, in fact, another header — yep, a header after a header — but this time, it contains information relating to our application.

The key bit — which I believe is the only bit that really matters to the Organiser II — is the `.BYTE (endvec-vec)/2`. This defines the number of _vectors_ we'll be using in our program.

Some of you may be wondering what a _vector_ is. A _vector_ is a word (so two bytes) that contains the memory address of some executable code. When the system _jumps_ to a vector, it essentially means that it is going to run the code at the address the vector points to.

Here we're defining some vectors:

```
vec:
	.WORD	install
	.WORD	remove
endvec:

install:
    ; TODO: Write install vector code

remove:
    ; TODO: Write remove vector code
```

`.WORD  install` adds the memory address that points to the code at (or will be at) `install:`, and `.WORD  remove` adds the memory address that points to `remove:`. The `.WORD     install` and `.WORD    remove` parts emit vectors that the Organiser II will jump to when the datapack is first installed, and then removed from the system, respectively.

These two vectors are useful as they allow us to insert and remove our menu item that the user will select to launch our application.

Let's start writing the installation code first, by getting it to simply print something to the screen. Modify `install:` to be:

```asm
install:
	ldaa	#$0C		; Clear screen
	os	dp$emit

	ldab	install_msg	; Print install message to screen
	ldx	#install_msg+1
	os	dp$prnt

	os	kb$getk		; Wait for keypress

	clc			; Return success signal
	rts

install_msg:
	.ASCIC	"Install vector"
```

This is the first bit of code we're writing now that is execually a bunch of executable instructions. Let's break it down.

1.
    `ldaa    #$0C` followed by `os   dp$emit` clears the screen. Here, we're loading in to the CPU's A register the value `#$0C`. `#$0C` is the ASCII code used to clear a terminal's screen.

    It's important to include the `#` before the `$`, as without it, `$0C` will cause the CPU to attempt to read the value at address `$0C` and load it into A, whereas we want to tell the CPU that _this_ is the value we want to load.

    `os dp$emit` calls a _system vector_ that reads the single byte in the A register and writes it to the screen. A _system vector_ is a vector that points to code in ROM, and in this case, does the complex task of talking to the display controller for us.