   .MODEL small

NUM_ARGS   equ     80h      ; 80h = # of Command Line Arguments
ARGS       equ     81h

   .STACK 100h
   .DATA
SERIAL_ID_STR_LEN EQU 8h
SERIAL_ID_STR DB "12345678",'$'

SERIAL_ID_LEN EQU 6h
SERIAL_ID DB 10,11,4,3,2,1,'$'        ;HD serial is 6 bytes string (the last 2 bytes represent the serial id)

STR_MSG_1 DB 'Do you want to change C: SerialID: (y/n)?','$'
STR_MSG_2 DB 'SerialID changed','$'
CRLF DB 13,10,'$'

    .CODE

  ;-------------------------------------------------- 
  ;-------------------------------------------------- Load first 8 bytes into SERIAL_ID_STR of DS
  ;-------------------------------------------------- 
  lea si, SERIAL_ID_STR     ;ds: SERIAL_ID_STR
  call LOAD_ARGS

  ;-------------------------------------------------- 
  ;-------------------------------------------------- upper case of SERIAL_ID_STR
  ;-------------------------------------------------- 
  mov ax, @data
  mov ds, ax
  lea si, SERIAL_ID_STR
  call UPPERCASE

  ;-------------------------------------------------- 
  ;-------------------------------------------------- Show arguments (SERIAL_ID_STR)
  ;-------------------------------------------------- 
  mov ax, @data
  mov ds, ax
  lea dx, SERIAL_ID_STR
  call PRINTF

  ;-------------------------------------------------- 
  ;-------------------------------------------------- Convert SERIAL_ID_STR into SERIAL_ID
  ;-------------------------------------------------- 
  mov ax, @data
  mov ds, ax
  lea si, SERIAL_ID     ;ds: bottom of SERIAL_ID
  add si, SERIAL_ID_LEN - 2  
  mov bx, si        ;bx: SERIAL_ID
  lea si, SERIAL_ID_STR   ;ds: SERIAL_ID_STR
  mov cx, 0h        ;counter

ConvertHexStr:
  call CONVERT_HEX    ;Convert 2 bytes of SI and put them in DX

  mov ax, @data      ;Write DX in SERIAL_ID (bx)
  mov ds, ax
  push si            ;pointer to SERIAL_ID_STR into the stack
  mov si, bx         ;SI=SERIAL_ID
  mov [si], dx
  dec si             ;SI=SERIAL_ID+1
  mov bx, si         ;BX=SERIAL_ID+1
  pop si             ;SI=SERIAL_ID_STR
  
  add si, 2h         ;increment si pointer
  inc cx             ;increment pointer cx
  cmp cx, 4h         ;serial has 4 bytes
  jne ConvertHexStr

  ;-------------------------------------------------- 
  ;-------------------------------------------------- Show SERIAL_ID
  ;-------------------------------------------------- 
  mov ax, @data
  mov ds, ax
  lea bx, SERIAL_ID
  mov cx, SERIAL_ID_LEN
  call PRINTN

  ;-------------------------------------------------- 
  ;-------------------------------------------------- Request confirmation
  ;-------------------------------------------------- 
  mov  ax,@data
  mov  ds, ax
  lea dx, CRLF
  call PRINTF
  lea dx, CRLF
  call PRINTF
  lea dx, STR_MSG_1
  call PRINTF
  lea dx, CRLF
  call PRINTF

  mov  ah, 1h  
  int  21h   
  cmp  al, 'y'
  jz   ChangeID
  cmp  al, 'Y'
  jnz  Done

ChangeID:
  ;-------------------------------------------------- 
  ;-------------------------------------------------- Change Serail ID
  ;-------------------------------------------------- 
  mov  ax,@data
    mov  ds, ax

    mov ah, 69h
    mov al, 1        ;1 set serial, 0 to get serial
    mov bl, 3        ;0 = default, 1 = A, 2 = B, 3 = C
  lea dx, SERIAL_ID
    int 21h

  ;-------------------------------------------------- 
  ;-------------------------------------------------- Show final message
  ;-------------------------------------------------- 
  mov  ax,@data
  mov  ds, ax
  lea dx, CRLF
  call PRINTF
  lea dx, STR_MSG_2
  call PRINTF
  lea dx, CRLF
  call PRINTF

Done:
  ;-------------------------------------------------- 
  ;-------------------------------------------------- End of program
  ;-------------------------------------------------- 
  mov ah, 4ch
  int 21h

  ;--------------------------------------------------
  ;-------------------------------------------------- 
  ;-------------------------------------------------- 
  ;--------------------------------------------------
  ;-------------------------------------------------- 
  ;-------------------------------------------------- 
  ;-------------------------------------------------- Procedures
  ;-------------------------------------------------- 
  ;--------------------------------------------------
  ;-------------------------------------------------- 
  ;--------------------------------------------------
  ;-------------------------------------------------- 
  ;-------------------------------------------------- 

PRINT1 PROC          
  ;-------------------------------------------------- 
  ;-------------------------------------------------- PRINT1
  ;-------------------------------------------------- 
  mov  dx, [bx]
  mov  ah, 02h
  int  21h
  ret
PRINT1 ENDP

PRINTN PROC          
  ;-------------------------------------------------- 
  ;-------------------------------------------------- PRINTN
  ;-------------------------------------------------- 
LPrint1:
  call PRINT1
  inc bx
  dec cx
  cmp cx, 0h
  jne LPrint1
  ret
PRINTN ENDP
    
PRINTF PROC          
  ;-------------------------------------------------- 
  ;-------------------------------------------------- PRINTF
  ;-------------------------------------------------- 
  mov ah, 09h
  int 21h
  ret
PRINTF ENDP

LOAD_ARGS PROC        
  ;-------------------------------------------------- 
  ;-------------------------------------------------- LOAD_ARGS
  ;-------------------------------------------------- 
  mov bx, ARGS-1
  
SkipSpaceg:        ; Skip initial spaces
  inc bx
  mov dx, [bx]
  cmp dl, 20h
  je SkipSpaces

  mov cx, 1h
  push ds

LoadArgs1:
  pop ds        ;restore ds address (arguments)
  mov dx, [bx]  ;copy content of ds:bx into dx
  push ds       ;push current ds address to the stack

  mov ax, @data  
  mov ds, ax
  mov [si], dx  ;copy dx content into ds:di (SERIAL_ID_STR char)

  inc bx        ;increment bx
  inc si        ;increment si
  inc cx        ;increment counter
  cmp cx, SERIAL_ID_STR_LEN  ;8 chars need to be copied
  jne LoadArgs1
  pop ds
  ret
LOAD_ARGS ENDP

CONVERT_HEX_0 PROC
  ;-------------------------------------------------- 
  ;-------------------------------------------------- CONVERT_HEX_0
  ;-------------------------------------------------- 
  mov bx, ax      ;Backup AX

ConvertHex1:
  inc al        ;Convert DL (eg: 41h -> 0Ah)
  inc ah
  cmp ah, dl
  jne ConvertHex1

  mov dl, al      ;Moltiply DL * 10h (eg: 0Ah -> A0h)
  mov al, 10h
  mul dl
  mov dl, al

  mov ax, bx      ;Restore AX
ConvertHex2:
  inc al
  inc ah
  cmp ah, dh
  jne ConvertHex2
  
  add dl, al      ;Sum AL and DL (eg: A0h + 0Bh -> ABh)
  mov dh, 0h      ;Converted number is stored in DL
  ret
CONVERT_HEX_0 ENDP


CONVERT_HEX_DL PROC
  ;-------------------------------------------------- 
  ;-------------------------------------------------- CONVERT_HEX_DL
  ;-------------------------------------------------- 
ConvertHex1:
  inc al        ;Convert DL (eg: 41h -> 0Ah)
  inc ah
  cmp ah, dl
  jne ConvertHex1

  mov dl, al      ;Moltiply DL * 10h (eg: 0Ah -> A0h)
  mov al, 10h
  mul dl
  mov dl, al
  ret
CONVERT_HEX_DL ENDP

CONVERT_HEX_DH PROC
  ;-------------------------------------------------- 
  ;-------------------------------------------------- CONVERT_HEX_DH
  ;-------------------------------------------------- 
ConvertHex2:
  inc al
  inc ah
  cmp ah, dh
  jne ConvertHex2
  
  add dl, al      ;Sum AL and DL (eg: A0h + 0Bh -> ABh)
  mov dh, 0h      ;Converted number is stored in DL

  mov dh, dl
  mov dl, 0h
  ret
CONVERT_HEX_DH ENDP

CONVERT_HEX PROC
  ;-------------------------------------------------- 
  ;-------------------------------------------------- CONVERT_HEX (DL + DH)
  ;-------------------------------------------------- 
  mov dx, [si]

  ;-------------------------------------------------- DL
  cmp dl, 39h      ;hex(asc("9")) = 39h
  ja ConvertLetterDL

  mov ah, 2Fh      ;hex(asc("0")) = 30h  (2F previous char)
  mov al, 0FFh    ;FFh + 01h = 01h
  jmp ConvertDL

ConvertLetterDL:
  mov ah, 40h      ;hex(asc("A")) = 41h  (40 previous char)
  mov al, 09h      ;09h + 01h = 0Ah

ConvertDL:
  call CONVERT_HEX_DL

  ;-------------------------------------------------- DH
  cmp dh, 39h
  ja ConvertLetterDH

  mov ah, 2Fh      
  mov al, 0FFh      
  jmp ConvertDH

ConvertLetterDH:
  mov ah, 40h
  mov al, 09h

ConvertDH:
  call CONVERT_HEX_DH
  ret
CONVERT_HEX ENDP

UPPERCASE PROC
  mov cx, 1h

UCase:
  mov dx, [si]

  ;-------------------------------------------------- DL
  cmp dl, 61h      ;hex(asc("a")) = 61h
  jb NoConvertDL    ;do not convert
  cmp dl, 7Ah      ;hex(asc("z")) = 7Ah
  ja NoConvertDL    ;do not convert
  sub dl, 20h

NoConvertDL:
  ;-------------------------------------------------- DH
  cmp dh, 61h      ;hex(asc("a")) = 61h
  jb NoConvertDH    ;do not convert
  cmp dh, 7Ah      ;hex(asc("z")) = 7Ah
  ja NoConvertDH    ;do not convert
  sub dh, 20h      

NoConvertDH:
  mov [si], dx

  inc si
  inc cx
  cmp cx, SERIAL_ID_STR_LEN
  jne UCase
  ret
UPPERCASE ENDP

  END
