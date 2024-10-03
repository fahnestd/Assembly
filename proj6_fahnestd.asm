TITLE proj6_fahnestd   (proj6_fahnestd.asm)

; Author: Devin Fahnestock
; Last Modified: 3/11/2023
; Portfolio Project
; Description:  displays the numbers, their mean, and their sum after 
;				the user inputs 10 positive or negative integers

INCLUDE Irvine32.inc
; (insert macro definitions here)

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Gets a string value from the user
;
; Receives:
; prompt = prompt to display before reading the users input
; output = the bytes read from the user
; bytesread = amount of characters read
;
; returns: output = users input string
; ---------------------------------------------------------------------------------

mGetString MACRO prompt:REQ, output:REQ, bytesread
	push	eax
	push	ecx
	push	edx

	mDisplayString	prompt

	mov		ecx, BUFFER_SIZE
	mov		edx, output
	call	ReadString

	mov		bytesread, eax
	pop		edx
	pop		ecx
	pop		eax
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays a string
;
; Receives:
; output = address of the string to write
;
; returns: none
; ---------------------------------------------------------------------------------

mDisplayString MACRO output:REQ
	push	edx

	cld
	mov		edx, output
	call	WriteString
	
	pop		edx
ENDM

; (insert constant definitions here)
	BUFFER_SIZE EQU 12 ;12 is the maximum digits available for a signed int in decimal form including the (+) or (-)
.data
; (insert variable definitions here)

	intro1		BYTE	"This is project 6, Made by Devin Fahnestock",0
	intro2		BYTE	"Enter 10 numbers and I will show you the mean and sum.",0
	outro1		BYTE	"Thanks for using my program!",0
	msg1		BYTE	"Here is your numbers you entered:",0

	msg2		BYTE	"Here is the sum: ",0
	msg3		BYTE	"Here is the mean truncated to an integer: ",0

	prompt		BYTE "Enter a number please: ",0
	errstr		BYTE "Error with input, try again!",0
	commastr	BYTE ", ",0

	asciiconv	BYTE 10 DUP(0)
	userString	BYTE BUFFER_SIZE DUP(0)
	ints		SDWORD 10 DUP(0)

	sum			DWORD 0
	mean		DWORD 0

.code
main PROC
; (insert executable instructions here)

	;show intro
	mDisplayString OFFSET intro1
	call	CrLf
	mDisplayString OFFSET intro2
	call	CrLf
	call	CrLf

	mov		eax, OFFSET ints ;set the reference to ints array into eax
	xor		ecx, ecx

_nextnum: ;loop for getting 10 numbers from user
	push	OFFSET prompt
	push	OFFSET errstr
	push	OFFSET userString
	push	eax
	call	ReadVal
	mov		ebx, [eax]
	add		sum, ebx ;keep the sum while going
	add		eax, 4 ;add 4 to the array offset to reference the next array index
	inc		ecx
	cmp		ecx, 10
	jl		_nextnum

	call	CrLf
	mDisplayString OFFSET msg1
	
	call	CrLf

	mov		eax, OFFSET ints 
	xor		ecx, ecx 
	jmp		_skip ;skips the comma the first time and therefore doesnt append a comma after the last value. 
	
	;values have been collected, now parse them back
_nextval: ;loop to show the 10 numbers back
	mDisplayString OFFSET commastr
_skip:
	push	OFFSET userString
	push	eax
	call	WriteVal
	add		eax, 4 ;add 4 to the array offset to reference the next array index
	inc		ecx
	cmp		ecx, 10
	jl		_nextval

	call	CrLf

	;show the sum

	mDisplayString OFFSET msg2
	push	OFFSET userString
	push	OFFSET sum
	call	WriteVal

	call	CrLf

	;div sum by 10 and show to user as mean
	xor		edx, edx
	mov		ebx, 10
	mov		eax, sum

	cdq
	idiv	ebx
	mov		mean, eax

	mDisplayString OFFSET msg3
	push	OFFSET userString
	push	OFFSET mean
	call	WriteVal
	call	CrLf
	call	CrLf

	;say goodbye
	mDisplayString OFFSET outro1
	call	CrLf

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; (insert additional procedures here)


; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Reads a string from the user and parses it into a signed DWORD, then writes the value to the output parameter
;
; Preconditions: none
;
; Postconditions: none
;
; Receives:
; [ebp + 20] = address of the prompt to show the user when collecting input
; [ebp + 16] = address of error string to show in case of an error
; [ebp + 12] = address of a buffer string, for parsing the integer
; [ebp + 8]  = the output address for the procedure to write the users integer to
;
; returns: Output parameter is the users integer
; ---------------------------------------------------------------------------------

ReadVal PROC
	LOCAL	isNeg : BYTE
	LOCAL	bytesread : DWORD
	push	eax
	push	ecx

	mov		isNeg, 0

	cld ; clear the direction flag to prep

_retry:
	;get input
	mGetString	[ebp + 20], [ebp + 12], bytesread
	cmp		bytesread, 12 ;check if too many or too little input
	jg		_error
	cmp		bytesread, 1
	jl		_error 
	mov		esi, [ebp + 12]
	xor		edx, edx
	xor		eax, eax
	mov		edi, eax

	lodsb ;load initial bit for checking signs
	cmp		al, '-'
	je		_negate  ;skip the first load after checking for neg (-)
	cmp		al, '+'
	je		_nextint ; if positive sign, jump to next value
	cmp		al, 0
	je		_error ; if nothing entered, retry
	jmp		_firstskip
_nextint:
	; validate the input
	lodsb

_firstskip:
	cmp		al, 0 ; check if end of string
	je		_exit
	
	imul	edx, 10 ; multiply by 10 since another value exists after
	jo		_error ; catch overflow error when multiplying 
	sub		al, 48 ; get the char to a digit

	;check if digit
	cmp		al, 0 ; check if nessecary, I think i can remove this then since any value should overflow to a larger than 9 value
	jl		_error
	cmp		al, 9
	jg		_error

	cmp		isNeg, 1
	je		_sub
	add		edx, eax ;add to value
_cont:
	jo		_error ;if overflow while positive, error
	jmp		_nextint

_sub: ; if the value is a negative, we subtract it instead of adding
	sub		edx, eax
	jo		_error ; catch subtraction overflow
	jmp		_cont

_negate:
	mov		isNeg, 1
	jmp		_nextint

_error: ; jump here if error, show message and then go back to retry
	mDisplayString [ebp + 16]
	call	CrLf
	jmp		_retry

_exit:
	mov		eax, [ebp + 8]
	mov		[eax], edx ;set the final value to the output parameter
	
	pop		ecx
	pop		eax
	ret		16
ReadVal ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Converts a signed integer to a ASCII Value and prints it to the console
;
; Preconditions: none
;
; Postconditions: none
;
; Receives:
; [ebp + 12] = address of a buffer string, for parsing the integer
; [ebp + 8]  = address of the integer to parse and display
;
; returns: none
; ---------------------------------------------------------------------------------

WriteVal PROC
	LOCAL	divisor : DWORD
	LOCAL	isNeg : DWORD

	mov		divisor, 10
	mov		isNeg, 0

	push	eax
	push	ecx
	push	edx
	mov		esi, [ebp + 8]
	mov		edi, [ebp + 12]
	xor		ecx, ecx ; clear ecx for counting
	xor		edx, edx ; clear edx for counting
	add		edi, 10
	std ;set the direction flag so that we move backwards while placing ascii values

	mov		al, 0 ; add a null terminator
	stosb	

	mov		eax, [esi + ecx * 4]
	
	cmp		eax, 0
	jge		_convint
	neg		eax
	mov		isNeg, 1

_convint:
	cdq
	idiv	divisor ;divide by 10, edx now holds the next value
	add		edx, 48
	push	eax
	mov		al, dl
	stosb  ; store the value to edi
	pop		eax
	cmp		eax, 0
	jne		_convint

	cmp		isNeg, 0
	je		_exit
	mov		al, '-' ; add the negative sign if negative
	stosb

_exit:
	mov		eax, edi
	inc		eax

	mDisplayString eax

	pop		edx
	pop		ecx
	pop		eax
	ret		8
WriteVal ENDP
	
END main
