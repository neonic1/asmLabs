.model tiny
.stack 100h
org 100h
jmp start
    messageWrongArguments db "Wrong aguments", 0Dh, 0Ah, '$'
    messageUsage db "Usage: lab5.com file_name.txt string_length", 0Dh, 0Ah, '$' 
    messageFileNotFound db "Error: file not found!", 0Dh, 0Ah, '$' 
    messagePathNotFound db "Error: path not found!", 0Dh, 0Ah, '$'
    messageTooManyFiles db "Error: too many files opened!", 0Dh, 0Ah, '$'
    messageAccessDenied db "Error: access denied!", 0Dh, 0Ah, '$'
    messageInvalidAccessMode db "Error: invalid access mode!", 0Dh, 0Ah, '$'
    messageInvalidIdentifier db "Error: invalid file identifier!", 0Dh, 0Ah, '$'
    messageValueTooBig db "Error: entered value is out of range! (Max: 5 digits)", 0Dh, 0Ah, '$' 
    messageCarryError db "Carry error: entered value is too big! (Max: 65535)", 0Dh, 0Ah, '$'
    messageStringCount db 0Dh, 0Ah, "String count: $"
    messageCR db 0Dh, 0Ah, '$'
    
    bufferSize EQU 100
    fileDescriptor dw 0
    reqiredLength dw 0
    buffer db bufferSize dup('$')
    stringCounter dw 0         
.code
start:   
    mov cx, [80h]
    cmp cx, 1
    jle wrongArguments
    cld
    mov di, 81h
    mov ax, ' '
    repz scasb
    inc cx
    dec di
    push di
    repnz scasb
    dec di
    mov [di], 0
    mov ah, 3Dh
    mov al, 0
    pop dx
    push cx
    xor cx, cx
    int 21h
    jc fileOpenError
    mov fileDescriptor, ax
    pop cx
    inc di 
    
    mov ax, ' '
    repz scasb
    inc cx
    dec di 
    xor dx, dx ;1-отрицательное, 0-положительное
    xor bx, bx ;кол-во цифр в числе
    mov ah, [di]
    cmp ah, "-"
    jnz checkNumber 
    mov dx, 1
    inc di
    dec cx
    mov ah, [di]
checkNumber: 
    push di
checkNumberLoop:
    cmp ah, ' '
    je endNumber
    cmp ah, 0Dh
    je endNumber    
    cmp ah, '0'
    jl wrongArguments
    cmp ah, '9'
    jg wrongArguments
    inc bx     
    inc di
    dec cx
    mov ah, [di]  
    jmp checkNumberLoop 
endNumber:
    cmp bx, 5
    jg valueTooBig
    cmp bx, 0
    je wrongArguments
    
    mov ax, ' '
    repz scasb
    dec di
    cmp byte ptr [di], 0Dh
    jne wrongArguments

    cmp dx, 1
    je fileParsing
    pop di
    mov cx, bx
    xor ax, ax
    xor bx, bx
    xor dx, dx 
    mov bx, 10
CMDToNumberLoop:
    push cx
    mov cl, [di]
    sub cl, '0'
    mul bx 
    jc carryError    
    add ax, cx
    jc carryError
    inc di
    pop cx
    loop CMDToNumberLoop
    mov reqiredLength, ax
    
fileParsing:
    mov cx, reqiredLength
    xor bx, bx;bl - символ. bh=1 - пропуск оставшейся части строки
    xor dx, dx;dl=1 - больше не выполнять считывание, dh=1 - если reqiredLength==0
    cmp reqiredLength, 0
    jne readNewBuffer
    mov dh, 1
readNewBuffer:
    call readFromFile
countLoop:
    cmp ax, 0
    je tryReadNewBuffer
    dec ax
    mov bl, [di]
    inc di
    cmp bl, 0Dh
    je newLine    
    cmp bl, 0Ah
    je newLine
    cmp bh, 1
    je countLoop
    cmp dh, 0
    je makeCountLoop
    inc stringCounter
    mov bh, 1
    jmp countLoop
makeCountLoop:    
    loop countLoop
    cmp ax, 0
    jne notEmptyBufferScip
    cmp dl, 0
    jne fileParsingEnd
    call readFromFile
notEmptyBufferScip:    
    dec ax
    mov bl, [di]
    inc di
    mov cx, reqiredLength
    cmp bl, 0Dh
    je smallString
    cmp bl, 0Ah
    je smallString
    inc stringCounter
    mov bh, 1
smallString:
    jmp countLoop 
     
newLine:
    cmp ax, 0
    jne notEmptyBufferNewLine
    cmp dl, 0
    jne fileParsingEnd
    call readFromFile
notEmptyBufferNewLine:    
    mov bh, 0
    mov cx, reqiredLength
    mov bl, [di]
    cmp bl, 0Dh
    je scipSymbolToNewLine
    cmp bl, 0Ah
    je scipSymbolToNewLine   
    jmp countLoop
scipSymbolToNewLine:
    dec ax
    inc di 
    jmp countLoop   

tryReadNewBuffer:
    cmp dl, 0
    je readNewBuffer

fileParsingEnd:    
    lea dx, messageStringCount
    call print_str
    mov ax, stringCounter
    call print_number
    lea dx, messageCR
    call print_str
    jmp exit
   
     
     
wrongArguments:
    lea dx, messageWrongArguments
    call print_str 
usageError:
    lea dx, messageUsage
    call print_str
    jmp exit 
    
fileOpenError:
    cmp ax, 02h
    je fileNotFound
    cmp ax, 03h
    je pathNotFound
    cmp ax, 04h
    je tooManyFiles
    cmp ax, 05h
    je accessDenied
    cmp ax, 0Ch
    je invalidAccessMode 
    jmp usageError
    
fileReadError:
    cmp ax, 05h
    je accessDenied
    cmp ax, 06h
    je invalidIdentifier
    jmp usageError
    
fileNotFound:
    lea dx, messageFileNotFound
    call print_str
    jmp usageError
pathNotFound:    
    lea dx, messagePathNotFound
    call print_str
    jmp usageError
tooManyFiles:
    lea dx, messageTooManyFiles    
    call print_str
    jmp usageError
accessDenied:    
    lea dx, messageAccessDenied
    call print_str
    jmp usageError
invalidIdentifier:
    lea dx, messageInvalidIdentifier    
    call print_str
    jmp usageError
invalidAccessMode:
    lea dx, messageInvalidAccessMode
    call print_str
    jmp usageError

valueTooBig:
    lea dx, messageValueTooBig
    call print_str
    jmp exit
carryError:
    lea dx, messageCarryError
    call print_str
    jmp exit 
 
exit:
    cmp fileDescriptor, 0
    je exitProgram
    mov ah, 3Eh
    mov bx, fileDescriptor
    int 21h
exitProgram:
    mov ah, 4Ch
    int 21h 
;******************PROCEDURES**********************
;вывод строки из dx на экран    
print_str PROC
    mov ah, 09h
    int 21h
    ret
print_str ENDP
;************************************************** 
;вывод числа из ax на экран
print_number PROC 
    xor cx, cx
    mov bx, 10
OUTPUT_LOOP:
    xor dx, dx 
    div bx
    push dx
    inc cx
    test ax, ax
    jnz OUTPUT_LOOP

    mov ah, 02h
OUTPUT_FROM_STACK:
    pop dx
    add dl, '0'
    int 21h
    loop OUTPUT_FROM_STACK
    
    ret
print_number ENDP
;**************************************************
readFromFile PROC
    push cx
    push bx 
    push dx 
    mov bx, fileDescriptor
    mov cx, bufferSize
    lea dx, buffer
    mov ah, 3Fh
    int 21h
    jc fileReadError
    lea di, buffer 
    pop dx
    pop bx 
    cmp ax, cx
    je notLastRead
    mov dl, 1 
notLastRead:
    pop cx    
    ret
readFromFile ENDP
;**************************************************
end start 