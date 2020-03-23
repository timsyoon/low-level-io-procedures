TITLE Designing Low-Level I/O Procedures     (ioProcs.asm)

; Author: Timothy Yoon
; Original Submission Date: March 15, 2020
; Course: CS 271
; Project Number: 6
; Description: This program obtains ARRAYLENGTH (10) signed integers from the user while validating them, stores
;	them in an array, and prints them, as well as their sum and average (i.e. arithmetic mean). The program uses
;	the ReadVal and WriteVal procedures and the getString and displayString macros, which have been implemented
;	by the programmer. ReadVal calls getString to obtain a string of digits from the user and converts the string
;	to a numeric value while validating the input. WriteVal converts a numeric value to a string of digits and
;	calls displayString to print the string on the console.
;
; Implementation notes: This program is largely constructed using procedures and macros.
;	All procedure parameters are passed on the system stack by value or by reference.
;	Addresses of prompts, identifying strings, and other memory locations are passed by address to the macros.
;	Used registers are saved and restored by the called procedures and macros.
;	It is assumed that the total sum of the numbers will fit inside a 32-bit register.
;	The average is rounded down to the nearest integer.
;	For extra credit option #1, the line number is only incremented if the user enters a valid input.

INCLUDE Irvine32.inc

getString	MACRO	prompt, buffer, str_len
	push	eax								;save registers
	push	ecx
	push	edx

  ;display prompt instructions
	mov		edx,prompt
	call	WriteString

  ;prompt user to enter a value
	mov		edx,buffer						;set up for call to ReadString
	mov		ecx,100							;maximum number of characters the user can enter 
											;	(plus 1 for the null byte at the end)
	call	ReadString						;number of entered characters in eax

  ;save the character count in memory
	mov		ecx,str_len
	mov		[ecx],eax

	pop		edx								;restore registers
	pop		ecx
	pop		eax
ENDM

displayString	MACRO	label_offset
	push	edx								;save register
	mov		edx,label_offset
	call	WriteString
	pop		edx								;restore register
ENDM

ARRAYLENGTH EQU 10							;number of elements in the array that will store the user's values
MAXSTRSIZE EQU 100

.data

prog_title			BYTE		"Programming Assignment 6: Designing Low-Level I/O Procedures",10,13,0
prog_author			BYTE		"Written by: Timothy Yoon",10,13,0
ec_1				BYTE		"**EC: Program numbers each line of user input and displays a running subtotal of the "
					BYTE		"user's numbers.",10,13,10,13,0
purpose_1			BYTE		"Please provide 10 signed decimal integers.",10,13,0
purpose_2			BYTE		"Each number needs to be small enough to fit inside a 32-bit register.",10,13,0
purpose_3			BYTE		"After you have finished inputting the raw numbers, I will display a list",10,13,0
purpose_4			BYTE		"of the integers, their sum, and their average value.",10,13,10,13,0
prompt_1			BYTE		"Please enter a signed number: ",0
prompt_2			BYTE		"Please try again: ",0
subtotal_msg		BYTE		"Your running subtotal is: ",0
error_msg			BYTE		"ERROR: You did not enter a signed number or your number was too big.",10,13,10,13,0
digit_str			BYTE		MAXSTRSIZE DUP(?)
period_space		BYTE		". ",0
comma_space			BYTE		", ",0
output_1			BYTE		"You entered the following numbers:",10,13,0
str_to_display		BYTE		MAXSTRSIZE	DUP(?)
sum_msg				BYTE		"The sum of these numbers is: ",0
avg_msg				BYTE		"The rounded average is: ",0
bye_msg				BYTE		"Thanks for playing!",0

input_count			DWORD		1																;number of user input attempts
str_len				DWORD		?																;length of digit string
sign				DWORD		5																;0 for + int, 1 for -, 5 for other
digit_count			DWORD		?																;number of digits in numeric value
array				SDWORD		ARRAYLENGTH DUP(?)												;stores valid user input values
num_val				SDWORD		?																;numeric value after string conversion
sum					SDWORD		0																;sum of all values entered so far
avg					SDWORD		?																;average of the elements in array

.code

main PROC
	push	OFFSET prog_title					;pass strings by reference
	push	OFFSET prog_author
	push	OFFSET ec_1
	push	OFFSET purpose_1
	push	OFFSET purpose_2
	push	OFFSET purpose_3
	push	OFFSET purpose_4
	call	introduction						;introduce the program to the user

	push	OFFSET sum							;pass strings and variables by reference
	push	OFFSET digit_count					;pass ARRAYLENGTH by value
	push	OFFSET str_to_display
	push	OFFSET prompt_1
	push	OFFSET prompt_2
	push	OFFSET error_msg
	push	OFFSET digit_str
	push	OFFSET str_len
	push	OFFSET sign
	push	OFFSET period_space
	push	OFFSET input_count
	push	OFFSET num_val
	push	OFFSET array
	push	OFFSET subtotal_msg
	push	ARRAYLENGTH
	call	fillArray							;get ARRAYLENGTH valid numbers from the user, storing them in an array

	push	OFFSET output_1						;pass strings, array, num_val, and digit_count by reference
	push	OFFSET comma_space					;pass ARRAYLENGTH by value
	push	OFFSET array
	push	OFFSET num_val
	push	OFFSET digit_count
	push	OFFSET str_to_display
	push	ARRAYLENGTH 
	call	displayArray						;print the elements of the array

	push	OFFSET sum							;pass sum and avg by reference
	push	OFFSET avg							;pass ARRAYLENGTH by value
	push	ARRAYLENGTH
	call	calcAvg								;calculate the average of the array elements

	push	OFFSET sum							;push sum, avg, digit_count and strings by reference
	push	OFFSET avg
	push	OFFSET sum_msg
	push	OFFSET avg_msg
	push	OFFSET digit_count
	push	OFFSET str_to_display
	call	displayCalculations					;display the sum and average of the array elements

	push	OFFSET bye_msg						;pass bye_msg by reference
	call	sayFarewell							;print a departing message to the user

	exit										;exit to operating system
main ENDP

;**********************************************************************************************************************
;Procedure to introduce the program to the user by displaying program information and directions.
;Implementation note: This procedure accesses its parameters by creating a stack frame and referencing parameters
;	relative to the top of the stack. The displayString macro is called to print strings to the console.
;receives: addresses of prog_title, prog_author, ec_1, purpose_1, purpose_2, purpose_3, and purpose_4 on the
;	system stack
;returns: program information and directions displayed
;preconditions: none
;postconditions: program information and directions displayed
;registers changed: none
;**********************************************************************************************************************

introduction PROC
	push	edx									;save registers
	push	ebp									;set up stack frame
	mov		ebp,esp

  ;display program title
	displayString	[ebp+36]					;pass offset of prog_title

  ;display program author
	displayString	[ebp+32]					;pass offset of prog_author

  ;display extra credit statement
	displayString	[ebp+28]					;pass offset of ec_1

  ;display purpose_1
	displayString	[ebp+24]					;pass offset of purpose_1

  ;display purpose_2
	displayString	[ebp+20]					;pass offset of purpose_2

  ;display purpose_3
	displayString	[ebp+16]					;pass offset of purpose_3

  ;display purpose_4
	displayString	[ebp+12]					;pass offset of purpose_4

	pop		ebp									;restore registers
	pop		edx
	ret		28									;restore stack to its original state
introduction ENDP

;**********************************************************************************************************************
;Procedure to obtain and validate ARRAYLENGTH (10) integers from the user while storing them in an array and displaying
;	a running subtotal of the values after each input.
;Implementation note: This procedure accesses its parameters by creating a stack frame and referencing parameters
;	relative to the top of the stack. The procedure calls ReadVal, WriteVal, and displayString.
;receives: addresses of sum, digit_count, str_to_display, prompt_1, prompt_2, error_msg, digit_str, str_len, sign,
;	period_space, input_count, num_val, array, subtotal_msg, and the value of ARRAYLENGTH on the system stack
;returns: first ARRAYLENGTH elements of array filled with validated signed integers, and the running subtotal
;	displayed on the console
;preconditions: array is initialized with space for at least ARRAYLENGTH SDWORD values
;postconditions: first ARRAYLENGTH elements of array filled with validated signed integers, and the running subtotal
;	displayed on the console
;registers changed: none
;**********************************************************************************************************************

fillArray PROC
	push	eax									;save registers
	push	ebx
	push	ecx
	push	edi
	mov		ebp,esp								;set up stack frame

  ;set up for filling the array
	mov		ecx,[ebp+20]						;ARRAYLENGTH as the loop counter in ecx
	mov		edi,[ebp+28]						;address of array in edi
	cld											;clear direction flag to move edi forward

fillNext:										;begin the loop

  ;pass parameters to ReadVal
	mov		ebx,[ebp+68]						;address of str_to_display in ebx
	push	ebx

	mov		ebx,[ebp+72]						;address of digit_count in ebx
	push	ebx

	mov		ebx,[ebp+64]						;address of prompt_1 in ebx
	push	ebx

	mov		ebx,[ebp+60]						;address of prompt_2 in ebx
	push	ebx

	mov		ebx,[ebp+56]						;address of error_msg in ebx
	push	ebx

	mov		ebx,[ebp+52]						;address of digit_str in ebx
	push	ebx

	mov		ebx,[ebp+48]						;address of str_len in ebx
	push	ebx

	mov		ebx,[ebp+44]						;address of sign in ebx
	push	ebx

	mov		ebx,[ebp+40]						;address of period_space in ebx
	push	ebx

	mov		ebx,[ebp+36]						;address of input_count in ebx
	push	ebx

	mov		ebx,[ebp+32]						;address of num_val in ebx
	push	ebx

	mov		ebx,[ebp+24]						;address of subtotal_msg in ebx
	push	ebx

	call	ReadVal								;get a string of digits and convert it to
												;	a numeric value while validating it

	mov		ebx,[ebp+32]						;address of num_val in ebx
	mov		eax,[ebx]							;value of num_val in eax
	stosd										;fill the current array element

  ;add num_val to the current sum
	mov		ebx,[ebp+76]						;address of sum in ebx
	add		eax,[ebx]							;eax = num_val + sum
	mov		[ebx],eax							;store the subtotal in sum

displaySubtotal:

  ;display descriptor for the running subtotal
	displayString	[ebp+24]					;display subtotal_msg

  ;pass parameters to WriteVal on the stack
	mov		ebx,[ebp+76]						;address of sum in ebx
	push	ebx

	mov		ebx,[ebp+72]						;address of digit_count in ebx
	push	ebx

	mov		ebx,[ebp+68]						;address of str_to_display in ebx
	push	ebx

	call	WriteVal							;display the running subtotal
	
	call	Crlf
	call	Crlf

  ;reset the value of num_val
	mov		eax,0
	mov		ebx,[ebp+32]						;address of num_val in ebx
	mov		[ebx],eax							;set num_val = 0

	loop	fillNext

	pop		edi									;restore registers
	pop		ecx
	pop		ebx
	pop		eax
	ret		60									;restore stack to its original state
fillArray ENDP

;**********************************************************************************************************************
;Procedure to display the contents of the array holding the ARRAYLENGTH (10) valid user input values.
;Implementation note: This procedure accesses its parameters by creating a stack frame and referencing parameters
;	relative to the top of the stack. The procedure calls WriteVal and displayString.
;receives: addresses of output_1, comma_space, array, num_val, digit_count, str_to_display, and the value of
;	ARRAYLENGTH on the system stack
;returns: ARRAYLENGTH elements of array displayed
;preconditions: user has entered valid values that have been stored in array
;postconditions: ARRAYLENGTH elements of array displayed
;registers changed: none
;**********************************************************************************************************************

displayArray PROC
	pushad										;save registers
	mov		ebp,esp								;set up stack frame

  ;print informational text before the array
	displayString	[ebp+60]					;pass address of output_1

  ;set up to iterate through array
	mov		esi,[ebp+52]						;address of array in esi
	mov		ecx,[ebp+36]						;ARRAYLENGTH in ecx as loop counter

nextElement:									;begin loop

  ;pass parameters to WriteVal on the stack
	mov		eax,[esi]							;value of current array element in eax
	mov		edx,[ebp+48]						;address of num_val in edx
	mov		[edx],eax							;value of current array element in num_val
	push	edx									;pass address of num_val

	mov		edx,[ebp+44]
	push	edx									;pass address of digit_count

	mov		edx,[ebp+40]
	push	edx									;pass address of str_to_display

	call	WriteVal							;convert num_val to a string of digits and display it

  ;check if the last element has been printed
	cmp		ecx,1
	je		noCommaSpace

  ;print a comma and a space after the value
	displayString	[ebp+56]					;pass address of comma_space

  ;prepare to print the next value in the array
	add		esi,4								;point to the next element in the array
	loop	nextElement

noCommaSpace:
	call	Crlf

endArrayDisplay:

	popad										;restore registers
	ret		28									;restore stack to its original state
displayArray ENDP

;**********************************************************************************************************************
;Procedure to calculate the average value of the ARRAYLENGTH (10) elements in the array.
;Implementation note: This procedure accesses its parameters by creating a stack frame and referencing parameters
;	relative to the top of the stack.
;receives: addresses of sum and avg, and the value of ARRAYLENGTH on the system stack
;returns: average of the array's ARRAYLENGTH elements stored in avg
;preconditions: total sum of the array's ARRAYLENGTH elements is calculated from keeping track of the running
;	subtotal in fillArray
;postconditions: average of the array's ARRAYLENGTH elements stored in avg
;registers changed: none
;**********************************************************************************************************************

calcAvg PROC
	pushad										;save registers
	mov		ebp,esp								;set up stack frame

  ;divide sum by ARRAYLENGTH
	mov		ebx,[ebp+36]						;value of ARRAYLENGTH in ebx (divisor)
	mov		ecx,[ebp+44]						;address of sum in ecx
	mov		eax,[ecx]							;value of sum in eax (dividend)
	cdq											;extend sign bit of eax into edx
	idiv	ebx									;quotient in eax
	mov		ebx,[ebp+40]						;address of avg in ebx
	mov		[ebx],eax							;store the average in memory
	
	popad										;restore registers
	ret		12
calcAvg ENDP

;**********************************************************************************************************************
;Procedure to display the sum and average values of the array's ARRAYLENGTH (10) elements.
;Implementation note: This procedure accesses its parameters by creating a stack frame and referencing parameters
;	relative to the top of the stack. The procedure calls WriteVal and displayString.
;receives: addresses of sum, avg, sum_msg, avg_msg, digit_count, and str_to_display on the system stack
;returns: values of sum and avg displayed
;preconditions: sum of the array's elements stored in sum, and the average of the array's elements stored in avg
;postconditions: values of sum and avg displayed
;registers changed: none
;**********************************************************************************************************************

displayCalculations PROC
	pushad										;save registers
	mov		ebp,esp								;set up stack frame

  ;print sum descriptor
	displayString	[ebp+48]					;print sum_msg

  ;display sum via call to WriteVal
	mov		eax,[ebp+56]						;address of sum in eax
	push	eax

	mov		eax,[ebp+40]						;address of digit_count in eax
	push	eax

	mov		eax,[ebp+36]						;address of str_to_display in eax
	push	eax

	call	WriteVal							;display value of sum
	call	Crlf

  ;print average descriptor
	displayString	[ebp+44]					;print avg_msg

  ;display avg via call to WriteVal
	mov		eax,[ebp+52]						;address of avg in eax
	push	eax

	mov		eax,[ebp+40]						;address of digit_count in eax
	push	eax

	mov		eax,[ebp+36]						;address of str_to_display in eax
	push	eax

	call	WriteVal							;display value of avg
	call	Crlf
	call	Crlf

	popad										;restore registers
	ret		24									;restore stack to its original state
displayCalculations ENDP

;**********************************************************************************************************************
;Procedure to display a departing message to the user.
;Implementation note: This procedure accesses its parameter by creating a stack frame and referencing the parameter
;	relative to the top of the stack. The procedure calls displayString.
;receives: address of bye_msg on the system stack
;returns: departing message displayed
;preconditions: none
;postconditions: departing message displayed
;registers changed: none
;**********************************************************************************************************************

sayFarewell PROC
	pushad										;save registers
	mov		ebp,esp								;set up stack frame

  ;print bye_msg
	displayString	[ebp+36]					;pass address of bye_msg
	call	Crlf

	popad										;restore registers
	ret		4									;restore stack to its original state
sayFarewell ENDP

;**********************************************************************************************************************
;Procedure to obtain from the user a string of digits and convert it to a numeric value while validating the input.
;Implementation note: This procedure accesses its parameters by creating a stack frame and referencing parameters
;	relative to the top of the stack. The procedure calls WriteVal, getString, and displayString.
;receives: addresses of str_to_display, digit_count, prompt_1, prompt_2, error_msg, digit_str, str_len, sign,
;period_space, input_count, num_val, and subtotal_msg on the system stack
;returns: validated user input stored as a numeric value in memory
;preconditions: none
;postconditions: validated user input stored as a numeric value in memory
;registers changed: none
;**********************************************************************************************************************

ReadVal PROC
	pushad										;save registers
	mov		ebp,esp								;set up stack frame

  ;number the line of user input
	mov		ebx,[ebp+44]						;address of input_count in ebx
	push	ebx

	mov		ebx,[ebp+76]						;address of digit_count in ebx
	push	ebx

	mov		ebx,[ebp+80]						;address of str_to_display in ebx
	push	ebx

	call	WriteVal							;print the current value of input_count

  ;print a period and a space
	displayString	[ebp+48]					;pass address of period_space

  ;get a string of digits from the user
	getString	[ebp+72], [ebp+60], [ebp+56]	;pass addresses of prompt_1, digit_str, and str_len

convertString:									;convert the string to a numeric value while validating it

  ;set up for string conversion
	mov		eax,0								;clear eax for lodsb
	mov		esi,[ebp+60]						;address of digit_str in esi
	mov		ebx,[ebp+56]						;address of str_len in ebx
	mov		ecx,[ebx]							;value of str_len in ecx as loop counter
	mov		ebx,[ebp+40]						;address of num_val in ebx
	mov		[ebx],eax							;set num_val equal to 0
	cld											;clear direction flag to move forward in esi

firstChar:										;handle the first character of the string

  ;if the string begins with '+' or '-'
	lodsb										;first character of digit_str in al

	cmp		al,43								;if the first character is '+'
	je		plusChar							;	indicate a positive integer

	cmp		al,45								;if the first character is '-'
	je		minusChar							;	indicate a negative integer

checkZero:

  ;if first or current character is '0'
	cmp		al,48
	je		zeroChar

  ;if string begins with an invalid character
	cmp		al,49								;if char < 49
	jb		errorBlock							;	print error message
	cmp		al,57								;if char > 57
	ja		errorBlock							;	print error message

positiveDigit:									;else the string begins with a positive digit

  ;set sign variable equal to 0
	mov		edx,0
	mov		edi,[ebp+52]						;address of sign in edi
	mov		[edi],edx							;set sign = 0 in memory

	jmp		positiveAlgo

plusChar:										;set sign variable equal to 0
	mov		edx,0
	mov		edi,[ebp+52]						;address of sign in edi
	mov		[edi],edx							;set sign = 0 in memory
	loop	nextChar

minusChar:										;set sign variable equal to 1
	mov		edx,1
	mov		edi,[ebp+52]						;address of sign in edi
	mov		[edi],edx							;set sign = 1 in memory
	loop	nextChar

zeroChar:
	cmp		ecx,1								;if the loop count is 1
	je		positiveAlgo						;	convert the only digit entered by the user
	lodsb										;else check if the next char is 0
	loop	checkZero

nextChar:
	lodsb

  ;if the next character is invalid
	cmp		al,48								;if char < 48
	jb		errorBlock							;	print error message

	cmp		al,57								;if char > 57
	ja		errorBlock							;	print error message

determineAlgo:									;else the character is a positive digit
	mov		ebx,[ebp+52]						;address of sign in ebx
	mov		edx,[ebx]							;value of sign in edx

	cmp		edx,0								;if sign has a value of 0
	je		positiveAlgo						;	use the algorithm meant for positive values

	cmp		edx,1								;if sign has a value of 1
	je		negativeAlgo						;	use the algorithm meant for negative values
												
;*******BEGIN CITED CODE*******
;The following code is not entirely my own.
;SOURCE: Lecture #23 Slides, "ReadInt Algorithm (pseudo-code)" slide
;Some of the following code is based on the algorithm provided below for
;converting a string of digits to a numeric value. The algorithm takes
;the form:
;
;	get str
;	x = 0
;	for k = 0 to (len(str) - 1)
;		if 48 <= str[k] <= 57
;			x = 10 * x + (str[k] - 48)
;		else
;			break

positiveAlgo:

  ;convert the character to a numeric value
	mov		ebx,0								;clear ebx

  ;get str[k] - 48
	mov		bl,al								;ASCII value of str[k] in bl
	sub		bl,48								;bl = str[k]-48
	
  ;get x = 10 * x
	mov		edi,[ebp+40]						;address of num_val in edi
	mov		eax,[edi]							;value of num_val in eax
	mov		edi,10
	mul		edi									;eax = 10 * num_val
	jo		errorBlock							;if overflow occurs, print an error message
	js		errorBlock							;if the sign flag is set, print an error message
	add		eax,ebx								;eax = 10 * num_val + (str[k] - 48)
	jo		errorBlock							;if overflow occurs, print an error message

  ;save the subtotal in memory
	mov		ebx,[ebp+40]						;address of num_val in ebx
	mov		[ebx],eax

	loop	nextChar
	jmp		endConvert

;********END CITED CODE********
												
;*******BEGIN CITED CODE*******
;The following code is not entirely my own.
;SOURCE: Lecture #23 Slides, "ReadInt Algorithm (pseudo-code)" slide
;Some of the following code is based on the algorithm provided below for
;converting a string of digits to a numeric value. The algorithm takes
;the form:
;
;	get str
;	x = 0
;	for k = 0 to (len(str) - 1)
;		if 48 <= str[k] <= 57
;			x = 10 * x - (str[k] - 48)
;		else
;			break

negativeAlgo:

  ;convert the character to a numeric value
	mov		ebx,0								;clear ebx

  ;get str[k] - 48
	mov		bl,al								;ASCII value of str[k] in bl
	sub		bl,48								;bl = str[k]-48
	
  ;get x = 10 * x
	mov		edi,[ebp+40]						;address of num_val in edi
	mov		eax,[edi]							;value of num_val in eax
	mov		edi,10
	imul	eax,edi								;eax = 10 * num_val
	jo		errorBlock							;if overflow occurs, print an error message
	sub		eax,ebx								;eax = 10 * num_val - (str[k] - 48)
	jo		errorBlock							;if overflow occurs, print an error message

  ;save the subtotal in memory
	mov		ebx,[ebp+40]						;address of num_val in ebx
	mov		[ebx],eax

	loop	nextChar

;********END CITED CODE********
	
endConvert:

incInputCount:									;after input validation, increase input_count
	mov		ebx,[ebp+44]						;address of input_count in ebx
	mov		eax,[ebx]							;value of input_count in eax
	inc		eax
	mov		[ebx],eax							;store the incremented input_count

resetSignVar:									;reset the sign variable
	mov		edx,5
	mov		ebx,[ebp+52]						;address of sign variable in ebx
	mov		[ebx],edx							;where 5 represents a neutral value (neither 0 nor 1)
	jmp		promptEnd

errorBlock:
	displayString	[ebp+64]					;print error_msg

  ;number the line before asking user for input
	mov		ebx,[ebp+44]						;address of input_count in ebx
	push	ebx

	mov		ebx,[ebp+76]						;address of digit_count in ebx
	push	ebx

	mov		ebx,[ebp+80]						;address of str_to_display in ebx
	push	ebx

	call	WriteVal							;display the user input line number

  ;print a period and a space
	displayString	[ebp+48]					;pass address of period_space

  ;get a string of digits from the user
  ;pass addresses of prompt_2, digit_str, and str_len to macro

	getString	[ebp+68], [ebp+60], [ebp+56]

  ;reset the sign variable
	mov		edx,5
	mov		ebx,[ebp+52]						;address of sign variable in ebx
	mov		[ebx],edx							;where 5 represents a neutral value (neither 0 nor 1)

	jmp		convertString

promptEnd:

	popad										;restore registers
	ret		48									;restore stack to its original state
ReadVal ENDP

;**********************************************************************************************************************
;Procedure to convert a numeric value to a string of digits.
;Implementation note: This procedure accesses its parameters by creating a stack frame and referencing parameters
;	relative to the top of the stack. The procedure calls the countDigits procedure and the displayString macro.
;receives: addresses of a variable of a numeric value to be converted (e.g. num_val is used in the comments below),
;	digit_count, and str_to_display on the system stack
;returns: str_to_display contains a string version of the numeric value and is displayed
;preconditions: the numeric value is a valid signed integer
;postconditions: str_to_display contains a string version of the numeric value and is displayed
;registers changed: none
;**********************************************************************************************************************

WriteVal PROC
	pushad										;save registers
	mov		ebp,esp								;set up stack frame

  ;pass parameters for call to countDigits
	mov		ebx,[ebp+44]
	push	ebx									;pass address of num_val

	mov		ebx,[ebp+40]
	push	ebx									;pass address of digit_count

	call	countDigits							;get the number of digits present in num_val

  ;determine which loop to use
	mov		ebx,[ebp+44]						;address of num_val in ebx
	mov		eax,[ebx]							;value of num_val in eax
	cmp		eax,0
	jge		forPosStr							;if num_val is positive, use the positive algorithm

forNegStr:										;algorithm for negative integers
  ;set up for the loop
	mov		edi,[ebp+36]						;address of the beginning of str_to_display in edi
	std											;set direction flag to move backwards in edi
	mov		ebx,[ebp+40]						;address of digit_count in ebx
	add		edi,[ebx]
	inc		edi									;edi = edi + digit_count + 1
												;	(space for a null char, digit_count characters, and a minus sign)

  ;insert null char at the end of the string
	mov		al,0
	stosb

  ;restore eax to value of num_val
	mov		ebx,[ebp+44]						;address of num_val in ebx
	mov		eax,[ebx]							;value of num_val in eax for repeated division

	mov		ebx,[ebp+40]						;address of digit_count in ebx
	mov		ecx,[ebx]							;value of digit_count in ecx as a loop counter

negWriteNext:									;begin loop
	cdq											;extend sign bit of eax into edx before signed division
	mov		ebx,10
	idiv	ebx									;remainder in edx
	mov		ebx,eax								;value of num_val in ebx
	mov		eax,edx								;remainder in eax
	neg		eax									;make remainder positive
	add		eax,48								;convert remainder to character code
	stosb
	mov		eax,ebx								;restore value of num_val to eax for next division
	mov		edx,0								;clear edx
	loop	negWriteNext

  ;insert minus sign in front of the string
    mov		eax,0
	mov		al,45
	stosb
	jmp		endWriting

forPosStr:
  ;set up for the loop
	mov		edi,[ebp+36]						;address of the beginning of str_to_display in edi
	std											;set direction flag to move backwards in edi
	mov		ebx,[ebp+40]						;address of digit_count in ebx
	add		edi,[ebx]							;edi = edi + digit_count
												;	(space for a null char and digit_count characters)

  ;insert null char at the end of the string
	mov		al,0
	stosb

  ;restore eax to value of num_val
	mov		ebx,[ebp+44]						;address of num_val in ebx
	mov		eax,[ebx]							;value of num_val in eax for repeated division

	mov		ebx,[ebp+40]
	mov		ecx,[ebx]							;value of digit_count in ecx as a loop counter

posWriteNext:									;begin loop
	cdq											;extend sign bit of eax into edx before signed division
	mov		ebx,10
	idiv	ebx									;remainder in edx
	mov		ebx,eax								;value of num_val in ebx
	mov		eax,edx								;remainder in eax
	add		eax,48								;convert remainder to character code
	stosb
	mov		eax,ebx								;restore value of num_val to eax for next division
	loop	posWriteNext	

endWriting:

  ;print the resulting string
	displayString	[ebp+36]					;pass address of str_to_display

	popad										;restore registers
	ret		12									;restore stack to its original state
WriteVal ENDP

;**********************************************************************************************************************
;Procedure to count the number of digits in a numeric value.
;Implementation note: This procedure accesses its parameters by creating a stack frame and referencing parameters
;	relative to the top of the stack.
;receives: addresses of a variable of a numeric value (e.g. num_val is used in the comments below) and digit_count on
;	the system stack
;returns: number of digits in the numeric value is stored in digit_count
;preconditions: numeric value is a valid signed integer
;postconditions: number of digits in the numeric value is stored in digit_count
;registers changed: none
;**********************************************************************************************************************

countDigits PROC
	pushad										;save registers
	mov		ebp,esp								;set up stack frame

	mov		ecx,1								;initialize counter
	mov		ebx,[ebp+40]						;address of num_val in ebx
	mov		eax,[ebx]							;value of num_val in eax

;*******BEGIN CITED CODE*******
;The ideas on which the following code is based are not entirely my own.
;SOURCE: TA John Burns in Slack:
;
;  https://class-cs271-40x-w20.slack.com/archives/CS45Y5DEG/p1583971751365100?thread_ts=1583971353.361500&cid=CS45Y5DEG
;
;In general, the two algorithms at the negativeDiv and positiveDiv labels below
;take a numeric value and repeatedly divide it by 10, incrementing a counter (ecx)
;after each division. Once the numeric value becomes 0, the counter should contain
;the number of digits that were present in the original numeric value.

  ;determine what algorithm to use
	cmp		eax,0
	jl		negativeDiv							;if num_val < 0, use the negative algorithm
	jmp		positiveDiv							;if num_val >= 0, use the positive algorithm

negativeDiv:									;algorithm for negative integers
	cdq											;extend sign bit of eax into edx for signed division
	mov		ebx,10
	idiv	ebx									;eax = eax / 10
	cmp		eax,0
	je		endCounting							;if eax = 0, the digit count is accurate
	inc		ecx									;otherwise continue counting digits
	jmp		negativeDiv

positiveDiv:									;algorithm for positive integers
	mov		edx,0								;clear edx
	mov		ebx,10
	div		ebx									;eax = eax / 10
	cmp		eax,0
	je		endCounting							;if eax = 0, the digit count is accurate
	inc		ecx									;otherwise continue counting digits
	jmp		positiveDiv
	
;********END CITED CODE********

endCounting:
	mov		ebx,[ebp+36]						;address of digit_count in ebx
	mov		[ebx], ecx							;store number of digits in digit_count

	popad										;restore registers
	ret		8									;restore stack to its original state
countDigits ENDP

END main
