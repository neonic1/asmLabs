;Удалить в строке слова, содержащие заданный набор букв
.model small
stack SEGMENT STACK
    db 256 DUP(?)
stack ENDS

data SEGMENT
    msg1 db 'Enter string:  $'
    msg2 db 0ah, 0dh, 'Enter substring: $'
    msg3 db 0ah, 0dh, 'Result string: $'
    
    strMaxL db 200
    strL db '$'
    str db 200 DUP('$')
    
    subStrMaxL db 200
    subStrL db '$'
    subStr db 200 DUP('$')  
data ENDS

code SEGMENT
    assume ds:data
    start:
    mov ax, data
    mov ds, ax
    mov es, ax
    xor ax, ax 
    
    lea dx, msg1
    call print_str
    
    lea dx, strMaxL
    call get_str
    
    lea dx, msg2
    call print_str
    
    lea dx, subStrMaxL
    call get_str
    
    cmp strL, 0
    je end
    cmp subStrL, 0
    je end
    
    call check_str
    
    xor cx, cx
    mov cl, strL
    cld
    lea si, str
    lea di, subStr
mainLoop:
    cmp [si], ' '
    je continueLoop
    cmp [si], 0Dh
    je end
    xor bx, bx
    mov bx, si     ;начало слова
    mov ax, 1      ;счетчик букв в слове
inLoop:
    inc si
    dec cx
    cmp [si], ' '
    je wordEnd
    cmp [si], 0Dh
    je wordEnd 
    inc ax
    jmp inLoop
    
continueLoop:  
    inc si
    jmp continueLoop1
    
wordEnd:
    call check_word
    inc cx 
    
continueLoop1:    
    loop mainLoop 
    
end:    
    lea dx, msg3
    call print_str
    
    lea dx, str
    call print_str
    
    mov ah, 4ch
    int 21h 
    
;******************PROCEDURES**********************
;вывод строки на экран    
print_str proc
    mov ah, 09h
    int 21h
    ret
print_str endp
;**************************************************
;буферезированный ввод строки
get_str proc
    mov ah, 0ah
    int 21h
    ret
get_str endp
;**************************************************
;проверка строки и подстроки на символы без эха и замена на пробелы
check_str proc
    lea bx, str
    xor cx, cx
    mov cl, strL
    mov si, 0
    xor dx, dx
L1: mov dl, [bx+si]
    cmp dl, 0
    jne noChange1
    mov [bx+si], ' '
noChange1:
    inc si
    loop L1
    
    lea bx, subStr
    xor cx, cx
    mov cl, subStrL
    mov si, 0
    xor dx, dx
L2: mov dl, [bx+si]
    cmp dl, 0
    jne noChange2
    mov [bx+si], ' '
noChange2:
    inc si
    loop L2
    
    ret
check_str endp    
;**************************************************     
;нахождение в слове подстроки
check_word proc 
    push cx
    cmp al, subStrL
    jl endCheckWord    ;если слово меньше подстроки 
    xor cx, cx
    mov cl, al
    sub cl, subStrL
    inc cl
    push si
    push bx
checkWordLoop:
    push di
    mov si, bx
    push cx
    xor cx, cx
    mov cl, subStrL
    repe cmpsb
    pop cx
    pop di
    jne notEqual
    je match
notEqual:
    inc bx
    loop checkWordLoop
    pop bx
    pop si
    jmp endCheckWord
match:
    pop bx    
    pop si
    
    pop cx
    push cx
    add cx, 2
    push di
    ;inc si  ;если не нужно, чтобы после удаленного слова оставался пробел
    mov di, bx
    repe movsb
    mov si, bx
    pop di
    
endCheckWord:
    pop cx
    ret        
check_word endp     
;**************************************************
     
     end start    
code ENDS