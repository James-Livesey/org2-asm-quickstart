.INCLUDE MOSVARS.INC
.INCLUDE MOSHEAD.INC
.INCLUDE MSWI.INC

.ORG $241B-25

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

.OVER prgstart
.EOVER

.OVER root

start:
	.WORD	$0000
	.BYTE	$00
	.BYTE	$41		; Device number
	.BYTE	$10		; Version 1.0
	.BYTE	(endvec-vec)/2	; Number of vectors

vec:
	.WORD	install
	.WORD	$ABCD
endvec:

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

remove:
	ldaa	#$0C		; Clear screen
	os	dp$emit

	ladb	remove_msg	; Print remove message to screen
	ldx	#remove_msg+1
	os	dp$prnt

	os	kb$getk		; Wait for keypress

	clc			; Return success signal
	rts

remove_msg:
	.ASCIC	"Remove vector"

.EOVER

.OVER prgend
.EOVER