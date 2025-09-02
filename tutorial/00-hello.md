# Hello, Psion!
In this guide, you'll be learning how to write a simple application for the Organiser II that installs itself to the main menu and displays a message when selected.

In order to learn starting with the basics, we'll be starting from a blank file. The full code we'll be writing is available in [hello.asm](../hello.asm). Before we do anything, please ensure you have followed the instructions listed in the [prerequisites section of the readme](../readme.md#prerequisites).

## Foundational knowledge
For this tutorial, we'll assume that you have a basic understanding of how a CPU works, in terms of memory, registers, and addressing. The Organiser II isn't too different from other computers from the 80s — only just miniaturised, and with slightly less RAM. However, it's a different beast when compared to modern computers (and particularly smartphones) as it lacks several features, such as memory protection and a multitasking operating system.

The Organiser II's system software resides in read-only memory (ROM), which is memory-mapped alongside random access memory (RAM). This means that addressing is linear, but some of it points to ROM, and the rest to RAM. When the Organiser II boots up, it executes code from ROM, and the built-in apps reside there too; but when executing an application from a datapack, this code is loaded into RAM.

Since there is no memory protection, an application can write to anywhere in RAM. (However, it can't write to ROM, as ROM is read-only.) This means that if there is an addressing-related bug in your code, your code may end up overwriting RAM and corrupting it. Remember that aside from datapacks, the Organiser II uses RAM as its primary place to store files, so ensure that all your files are backed up before attempting to run your own code.

There may be times where your code causes the Organiser II to crash or get into an infinite loop, which means removing the battery. When you do this, you'll lose all the files stored in RAM. Even more reason to back up your files! Luckily, the emulator — which we'll be using here for development purposes — is much less risky to experiment with.

It's worth familiarising yourself with the instruction set we'll be using. It's relatively simple as there aren't that many instructions. The [MC6801/03 Instruction Set Summary](https://cdn.hackaday.io/files/1776067598695104/MC6801-6803%20INSTRUCTION%20SET%20SUMMARY.pdf) is worth a read — it's not the same CPU as the HD6303 the Organiser II uses, but there is significant overlap in the instruction set.

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

The first byte — `$6A` — tells the Organiser II that this datapack is bootable. All the rest of the bytes in the header more-or-less match what would be seen at the start of a general-purpose datapack.

## Writing our relocatable code
The Organiser II's operating system is very clever for its time — it allows you to have more than one application loaded into memory at once; up to three, in fact (corresponding to the two datapack slots, and the top slot connector, which acts as a special datapack slot).

To achieve this, the operating system may load applications _anywhere_ into memory, depending on the model of Organiser II, and what other devices/applications are loaded. However, application code must be designed to allow the operating system to modify it so that all the absolute addresses can be 'fixed up' to reference data in wherever the application is loaded. This is achieved using Psion's relocatable format.

The actual magic happens when we get to `.OVER root`: this defines an _overlay_, called `root`. In practice, `.OVER` outputs [some extra metadata](https://www.jaapsch.net/psion/tech11.htm#p11.1.2) that tells the Organiser II's operating system which bytes in the machine code to modify in order to ensure that all the addresses are 'fixed up' after the code is loaded from the datapack into RAM. An _overlay_ is essentially a single unit of code that is meant to be relocatable.

This is where the `.ORG` line from earlier comes in — the offset in use is sufficiently large (`$241B`) to ensure that all machine code instructions use addresses that are two bytes long, and thus are easily modifiable by the operating system.

To tie it all off, the `.WORD %root-%xx` from earlier tells the Organiser II where it should expect the relocatable code to be in the datapack (`%root-%xx` refers to the number of bytes after the header), and `.WORD %prgend-%root` tells the Organiser II how long that code is so that it can copy it to RAM.

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

Some of you may be wondering what a _vector_ is. A _vector_ is a word (so two bytes) that contains the memory address of some executable code. When the system _jumps_ to a vector, it means that the CPU is going to run the code at the address the vector points to.

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

`.WORD install` adds the memory address that points to the code at (or will be at) `install:`, and `.WORD remove` adds the memory address that points to `remove:`. The `.WORD install` and `.WORD remove` parts emit vectors that the Organiser II will jump to when the datapack is first installed, and then removed from the system, respectively.

These two vectors are useful as they will later be used to allow us to insert and remove our menu item that the user will select to launch our application.

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

This is the first bit of code we're writing now that is actually a bunch of executable instructions. Let's break it down.

1.	`ldaa #$0C` followed by `os dp$emit` clears the screen. Here, we're loading into the CPU's A register the value `#$0C`. `#$0C` is the ASCII code used to clear a terminal's screen.

	It's important to include the `#` before the `$`, as without it, `$0C` will cause the CPU to attempt to read the value at address `$0C` and load it into A, whereas we want to tell the CPU using `#` that _this_ is the _immediate_ value we want to load.

	`os dp$emit` calls a _system vector_ that reads the single byte in the A register and writes it to the screen. A _system vector_ is a vector that points to code in ROM, and in this case, does the complex task of talking to the display controller for us. You'll find that `dp$emit` is a word that's defined in `MSWI.INC`.

2.	`ldab install_msg` and `ldx #install_msg+1` loads the size and address, respectively, of the message we want to print out. At `install_msg`, `.ASCIC` defines a length-prefixed string, also known as a Pascal string, where the first byte contains the length of the string, and the subsequent bytes are the characters of the string itself. This is handy as `ldab install_msg` loads the first byte from `install_msg` into the B register, which is the string's length. We then load the string's address into the X register, offset by 1 to skip over the length byte, using `ldx #install_msg+1`.

3.	`os dp$prnt` then calls a system vector that prints out a string onto the display. Here, it expects the length of the string to be in the B register, and the address of the first character in the X register, as we have already done.

4.	`os kb$getk` calls a system vector that waits for the user to press a key before returning. The key code of the key pressed will then be stored in the B register, but we don't care about that for now.

5.	`clc` and `rts` finish off our _install_ vector's code by first clearing the carry bit in the _condition code register_ using `clc`, to send a success signal to the system, and then returning back to the operating system with `rts` (which is the _return from subroutine_ instruction).

It's now your turn to also write code for the _remove_ vector (`remove:`) to print a different message.

## Let's try it out
It's now time to assemble the code you've written so far. To do this in Visual Studio Code, simply press <kbd>F5</kbd>. Otherwise, run `./build.sh $FILE --test`, where `$FILE` is the filename of the `.asm` file you're working on.

This will run the assembler, convert the raw binary file for the datapack into a `.opk` file used by emulators, and then start the emulator with this `.opk` file loaded. If there are problems when assembling your code, the assembler will inform you of any syntax errors that might be present. If everything goes to plan, you should see `Install vector` appear on the display after Psion's copyright message goes away. Press any key, and you should be taken to the main menu. We haven't written any code to add an item to the main menu yet, so you'll just see the default list of applications for now.

You can also test the code you wrote for the _remove_ vector while you're in the emulator by selecting **Datapacks**, then **Slot B**, then **Eject**. On the main menu, once you press <kbd>F1</kbd> (the emulator's mapping of the <kbd>ON</kbd> key), the _remove_ vector will be called, displaying your `Remove vector` message, before your code is unloaded from RAM by the operating system.

## A quick word on registers
We've been diving into writing assembly code so far without too much knowledge of the CPU itself. It's important to understand some specific details of the CPU in order to begin writing programs of our own. The CPU has 7 logical registers present: our 8-bit _accumulators_ **A** and **B**, our 16-bit _double accumulator_ **D**, _index register_ **X**, _stack pointer_ **SP** and _program counter_ **PC**, and our 8-bit _condition code register_ **CCR**. Let's go through them:

* **A** can hold an 8-bit byte, and is used for general-purpose data, such as adding numbers.
* **B** is used for the same purpose as **A**.
* **D** holds a 16-bit word, and is the same register storage area that is used for **A** and **B**. Here, **A** is stored as the high byte of **D**, and **B** is stored as the low byte of **D**. This means that if we store `$12` in **A** and `$34` in **B**, **D** will contain `$1234` as a result. Similarly, if we store `$5678` in **D**, **A** will become `$56`, and **B** `$78`.
* **X** holds a 16-bit word, and is usually used to store addresses. However, it can be used for general-purpose storage when **D** is already in use — but note that there won't be any instructions to directly perform arithmetic operations on **X**, unlike with **D**.
* **SP** holds the 16-bit address of the top of the _stack_, used to track the order in which subroutines are called so that `rts` returns to the previous subroutine. It's best not to fiddle with this unless you know what you're doing.
* **PC** holds the 16-bit address of the next instruction to execute.
* **CCR** is an 8-bit register that contains flags which may be set or unset, depending on the instructions executed. For example, its least significant bit will be set if `add` results in an integer overflow.

Once again, the [MC6801/03 Instruction Set Summary](https://cdn.hackaday.io/files/1776067598695104/MC6801-6803%20INSTRUCTION%20SET%20SUMMARY.pdf) gives a good overview of the registers in use. You don't have as many registers to work with compared to that of an x86 CPU, but it's enough to be able to write useful programs with little difficulty. You will just need to  load and store data to and from RAM more frequently.