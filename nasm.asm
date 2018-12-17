; CS 2XA3 FINAL PROJECT
; Nico Stepan
; 001404582
;
; issues:
; I have noticed that due to the number of comments, unless
; the terminal window is large, the code will not compile properly
; as the comments begin on a new line. thus, maximize window before
; copy and pasting this code.
;

%include "asm_io.inc"

extern rconf

SECTION .data       ; initialized data
start: db "------The program has started------",10,10,0
startingConfig: db "initial configuration",10,10,0
space: db " ",0
disk: db "o",0
peg: db "|",0
bottom: db "XXXXXXXXXXXXXXXXXXXXXXX",10,10,0
endConfig: db "final configuration",10,10,0
finished: db "------The program has finished and terminated successfully------",10,0

e1: db "Wrong number of arguments",10,10,0
e2: db "Invalid integer",10,10,0

; The program uses an integer array of length 9 to represent a peg
; Each item of the array represents the size of the disk at that position on the disk
pegArray: dd 0,0,0,0,0,0,0,0,0

SECTION .bss          ; uninitialized input data section
pegDisks: resd 1
pegSpaces: resd 1

SECTION .text         ; code section
global asm_main

asm_main:                   ; program start
     enter 0,0
    pusha

    ; get number of disks on the peg and make sure
    ; it's indeed just one argument
    mov eax, dword [ebp+8]
    cmp eax, dword 2 
    jne WRONG_ARGC          ; if not, jump to error string

    ; check that the argv[1] between 2 and 9 (inclusive)
    mov ebx, dword [ebp+12]
    mov eax, dword [ebx+4]
    mov bh, byte [eax]
    cmp bh, '2'             ; make sure it's greater than 2
    jb WRONG_INT            ; else, jump to error string
    cmp bh, '9'             ; make sure it's less than 9
    jg WRONG_INT            ; else, jump to error string

    ; make sure there's only one argument by checking that
    ; the second one is the null character
    sub bh, '0'
    mov [pegDisks], bh      ; initialize pegDisks with the value in bh
    mov bh, byte [eax+1]    ; move the second byte into bh
    cmp bh, byte 0          ; compare with 0
    jne WRONG_INT           ; jmp to error if not 0
    mov ecx, pegArray       ; exc now stores pegArray

    ; push disks onto stack and call rconf (which is already
    ; prepared for us in driver.c)
    ; this creates a random initial configuration
    push dword [pegDisks]   ; push pegDisks onto stack
    push ecx                ; push the pegArray onto stack
    call rconf              ; call rconf

    ; The program displays the initial peg configuration as
    ; created by rconf and pauses and waits for the user to
    ; depress a key.
    ; NOTE: instead of pressing 'return' or 'enter', you could just type a
    ; bunch of characters randomly and that will result in the final configuration
    ; being displayed
    add esp, 8              ; fix the stack
    mov eax, start          ; move the start string into eax
    call print_string       ; print the start string
    mov eax, startingConfig ; move the initial config string into eax
    call print_string       ; print it 

    ; The display of the peg configuration is done by a subprogram
    ; showp that you have to write. The subprogram showp expects
    ; two parameters on the stack; on top of the stack the address
    ; of the array representing the peg, and below the number of disks.
    push pegArray           ; push pegArray onto stack
    push dword [pegDisks]   ; push pegDisks onto stack with specified size
    call showp              ; call showp

    ; Then the initial configuration is passed to a subprogram sorthem
    ; that you have to write. The subprogram sorthem expects two parameters
    ; on the stack, at the top the address of the peg and below the number of disks.
    call sorthem            ; call sorthem

    ; print endConfig string and display the peg configuration one final time
    ; by calling showp
    mov eax, endConfig      ; move the final config string into eax
    call print_string       ; print it
    call showp              ; call showp 
    
    ; print the finished string 
    mov eax, finished       ; move finished string into eax
    call print_string       ; print it
    add esp, 8              ; fix the stack
    jmp POPNLEAVE           ; jump to the pop and leave function

sorthem:
    enter 0,0
    pusha

    ; get the two parameters on the stack
    ; number of disks, address of the array representing the peg
    mov edx, [ebp+8]        ; get pedDisks in edx
    mov ecx, [ebp+12]       ; get pegArray in ecx

    ; Base case = the number of disks is 1. Do nothing, return
    ; to the caller
    cmp edx, dword 1        ; check if pegDisks is 1
    je POPNLEAVE            ; if it is, jump to pop and leave

    ; First invocation of sorthem (referred to as sorthem1) from 
    ; sorthem: ecx contains the first argument 100008, edx contains 
    ; the second argument. this is taken exactly from 
    ; http://www.cas.mcmaster.ca/~franek/courses/cs2xa3/slides/xp.pdf
    add ecx, 4      ; ecx+4
    push ecx        ; push it onto the stack
    dec edx         ; edx-1
    push edx        ; push it onto the stack

    ; It then calls sorthem with ecx+4 and edx-1 
    call sorthem    ; call sorthem again with new values in stack
    add esp, 8      ; fix the stack
    sub ecx, 4      ; go to next value in array
    mov ebx, edx    ; put pegDisks into ebx

; sorting recursive function to compute the sorting on the peg
; really all this is is sorting a one-dimensional array
; showp will be called to display the results
; multiple times
SortFunction:
    cmp ebx, 0      ; base case
    je Sorted       ; if ebx is 0, jmp to sorted
    mov eax, [ecx]  ; move the disk into eax
    cmp eax, [ecx+4]; cmp current disk to the next disk
    dec ebx         ; ebx - 1
    jae SortFunction; recursively call if above or equal
    mov esi, eax    ; move eax into an additional esi register
    mov eax, [ecx+4]; move next disk into eax
    mov [ecx], eax  ; move eax into address of disk
    mov eax, esi    ; move additional esi register information into eax
    mov [ecx+4], eax; move that into the location of next disk
    add ecx, 4       
    jmp SortFunction;recursively call again

Sorted:
    push pegArray        ; push the array onto stack
    push dword [pegDisks]; need to specify size of the disks data (and push)
    call showp           ; begin displaying the stuff on peg
    add esp, 8           ; fix the stack before leaving
    jmp POPNLEAVE        ; (after showp)
    ;
;
; The subprogram showp expects two parameters on the stack; on top 
; of the stack the address of the array representing the peg, and 
; below the number of disks.
showp:
    enter 0,0
    pusha
    mov esi, [ebp+12]   ; get disks and peg array and put them into
    mov eax, [ebp+8]    ; esi and ex registers
    mov ecx, eax         ; move peg array into ecx
    dec eax             ; decrement eax to preserve disks
    mov bh, 4           ; fix bh
    imul bh             ; fix bh(unsigned multiplication)
    mov edi, eax        ; move eax into temporary edi register
    add esi, edi        ; esi now holds final value in peg array
    ; note, sort in descending order

DisplayLoop:
    mov edx, 11         ; setup
    sub edx, [esi]      ; get current position
    mov [pegSpaces], edx; get the peg spaces
    call RowStart       ; begin displaying row on the peg
    sub esi, 4          ; decrease esi to get next value in array
    loop DisplayLoop    ; jump into loop again for next row
    mov eax, bottom     ; move bottom string into eax
    call print_string   ; print it
    call read_char      ; wait for user to press a key
    jmp POPNLEAVE

; these set of functions are aimed at printing out not only the disks
; on the peg for a given row, but also the spaces corresponding
; to said row
RowStart:
     enter 0,0
    pusha
     mov ebx, [pegSpaces]    ; get spaces
    mov ecx, 0              ; set ecx to 0

; recursive function that prints the number of spaces on the
; left side of the peg until equal (or above) to ecx (which starts at 2 and
; gets incremented)
LeftOfPegSpaces:
    cmp ecx, ebx         ; compare ecx to spaces
    jae ToLeftDisks      ; if ecx is above or equal to spaces, jmp to disks
    mov eax, space       ; move the space (' ') into eax
    call print_string       ; print it
    inc ecx             ; increment ecx
    jmp LeftOfPegSpaces;recursively call this again

ToLeftDisks:
    mov ebx, [esi]      ; get ebx ready for disks
    mov ecx, 0          ; reset ecx

; recursive function that prints the number of disks on the 
; left side of the peg before jumping to the peg itself
LeftOfPegDisks:
    cmp ecx, ebx        ; if disks is 0, go to peg
    jae ToPeg           ; jmp to peg
    mov eax, disk       ; move disk string into eax
    call print_string   ; print it
    inc ecx             ; increment ecx
    jmp LeftOfPegDisks  ; recursively call this again

; this just prints out the peg
ToPeg:
    mov eax, peg        ; move peg string into eax
    call print_string   ; print it
    mov ebx, [esi]      ; get ebx ready for disks
    mov ecx, 0          ; reset ecx

; recursive function that prints the number of disks on the 
; right side of the peg
; this is the same procedure as LeftOfPegDisks, however, now we don't 
; need to worry about the peg ( | ) in the middle
RightOfPegDisks:
    cmp ecx, ebx        ; if ecx is 0, goto right spaces
    jae ToRightSpaces   
    mov eax, disk       ; move disk string to into eax
    call print_string   ; print it
    inc ecx             ; increment ecx
    jmp RightOfPegDisks ; recursively call this again

ToRightSpaces:
    mov ebx, [pegSpaces]; move peg spaces into ebx
    mov ecx, 0          ; reset ecx

; recursive function that prints the number of spaces on the
; left side of the peg until equal (or above) to ecx
RightOfPegSpaces:
    cmp ecx, ebx        ; if spaces is 0, go to row end
    jae RowEnd          
    mov eax, space      ; else, move space into eax
    call print_string   ; print it
    inc ecx             ; increment ecx
    jmp RightOfPegSpaces; recursively call this again

; after the right of peg spaces have been printed, the only thing
; left todo is print a new line 
RowEnd:
    call print_nl       ; print \n
    jmp POPNLEAVE

; error stuff to ensure proper input
WRONG_ARGC:
     mov eax, e1
    call print_string
    jmp POPNLEAVE

WRONG_INT:
     mov eax, e2
    call print_string
    jmp POPNLEAVE

POPNLEAVE:
    popa
    leave
    ret

;;;;;;;end;;;;;;
