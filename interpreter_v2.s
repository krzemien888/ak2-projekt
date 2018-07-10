# as -g -32 interpreter_v2.s -o v2.o
# ld -m elf_i386  v2.o -o v2
# ./v2 inputFile

#TODO: Nested loop.
#TODO: Out of tape condition.
#TODO: Add some new instructions.

SYSREAD = 3
SYSWRITE = 4
STDIN = 0
STD0UT = 1
FOPEN = 5
FCLOSE = 6
SYSEXIT = 1
EXIT_SUCCESS = 0
SYSCALL = 0x80
RDONLY = 0
MAX_INPUT_SIZE = 0xFFFFFF
MAX_TAPE_SIZE = 0xFFFF
CELL_SIZE = 0xFF

.align 32

.data
	#NOT WORKING! Only hard-coded ascii works. 
	#incCell: .long 0x56696e63
	#0x56, 0x69, 0x6e, 0x63	#Vinc
	
	#decCell: .long 0x56646563
	#.byte 0x56, 0x64, 0x65, 0x63	#Vdec

	#nextCell: .long 0x566e7874

	#0x56, 0x6e, 0x78, 0x74	#Vnxt

	#prevCell: .long 0x56707276
	#0x56, 0x70, 0x72, 0x76	#Vprv

	#putChar: .long 0x56707574
	#.byte 0x56, 0x70, 0x75, 0x74	#Vput


	errorInputMsg: .ascii "Instrucion unknown.\n"
	errorInputMsgLen =.-errorInputMsg

	errorEndOfTapeMsg:	.ascii "Error. Pointer out of tape.\n"
	errorEndOfTapeMsgLen = .-errorEndOfTapeMsg

.bss
	.lcomm inputFile, MAX_INPUT_SIZE
	.lcomm tape, MAX_TAPE_SIZE
	.lcomm size, 4
	
.text
	.global _start

_start:
	pop %ebx	#argc	- discard
	pop %ebx	#arg[0] - discard
	pop %ebx	#arg[1] - input file name


	#Open file to read with.
	movl $FOPEN, %eax
	movl $RDONLY, %ecx
	movl $0666, %edx
	int $SYSCALL

	#Read from opend file to buffer.
	movl %eax, %ebx
	movl $SYSREAD, %eax
	movl $inputFile, %ecx
	movl $MAX_INPUT_SIZE, %edx
	int $SYSCALL
			
	movl $tape, %esi 		#Data pointer initialization (used in tape).
	movl $inputFile, %edi	#Current position pointer (in read file).

dataProcessing:	
	cmpl $0, (%edi)				#Check if end of input data.
	je end 						#If true - stop retriving.

	cmpl $0x74786e56,  (%edi) 		#Vnxt (Increment data pointer.)
	je incDataPointer

	cmpl $0x76727056, (%edi) 		#Vprv (Decrement data pointer.)
	je decDataPointer
	
	cmpl $0x636e6956, (%edi) 		#Vinc  (Increment cell value.)
	je incrementCell

	cmpl $0x63656456, (%edi) 		#Vdec  (Decrement cell value.)
	je decrementCell

	cmpl $0x74757056, (%edi) 		#Vput	(Put char.)
	je printCell

	cmpl $0x74656756, (%edi) 		#Vget	(Get char.)
	je getByte

	cmpl $0x74736c56, (%edi) 		#Vlst	(Beginning of the loop.)
	je loopStart

	cmpl $0x6e656c56, (%edi) 		#Vlen	(End of the loop.)
	je loopEnd

	jmp errorInput 					#Instruction unknown. Stop.

incDataPointer:
	inc %esi
	jmp incCurrentPos

decDataPointer: 
	dec %esi
	jmp incCurrentPos

incrementCell:
	addb $1, (%esi)
	jmp incCurrentPos

decrementCell: 
	subb $1, (%esi)
	jmp incCurrentPos

printCell:
	movl $SYSWRITE, %eax
	movl $STD0UT, %ebx
	movl %esi, %ecx
	movl $1, %edx
	int $0x80
	jmp incCurrentPos

#TODO: clean buffer to delete 'enter'
getByte:
	movl $SYSREAD, %eax
	movl $STDIN, %ebx
	movl %esi, %ecx 	
	movl $1, %edx
	int $0x80
	jmp incCurrentPos

loopStart:
	pushl %edi 		#Keep track of instrucion pointer position (loop start).
	jmp incCurrentPos

loopEnd:
	cmpb $0x00, (%esi)
	je incCurrentPos

	popl %edi
	jmp loopStart


errorInput:
	movl $SYSWRITE, %eax
	movl $STD0UT, %ebx
	movl $errorInputMsg, %ecx
	movl $errorInputMsgLen, %edx
	int $0x80
	jmp end

errorEndOfTape:
	movl $SYSWRITE, %eax
	movl $STD0UT, %ebx
	movl $errorEndOfTapeMsg, %ecx
	movl $errorEndOfTapeMsgLen, %edx
	int $0x80
	jmp end


incCurrentPos:
	addl $4, %edi
	addl $4, %edx
	jmp dataProcessing


end:

	movl $SYSEXIT, %eax
	movl $EXIT_SUCCESS, %ebx
	int $SYSCALL


