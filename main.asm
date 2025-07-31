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

.OVER root

start:
	.WORD	$0000
	.BYTE	$00
	.BYTE	$41		; Device number
	.BYTE	$10		; Version 1.0
	.BYTE	(endvec-vec)/2	; Number of vectors

vec:
	.WORD	install
	.WORD	remove
	.WORD	lang
endvec:

install:
	; INSTALL VECTOR
	; Code placed here will run when the Organiser detects that the datapack
	; has been inserted.

	clc			; Return success signal
	rts

remove:
	; REMOVE VECTOR
	; Code placed here will run when the Organiser detects that the datapack
	; has been removed.

	clc			; Return success signal
	rts

lang:
	; LANGUAGE VECTOR
	; Code placed here can be used to add new functions to OPL.

	sec			; Return 'no match' signal
	rts

.EOVER

.OVER prgend
.EOVER