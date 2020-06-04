.model small

stack SEGMENT STACK
    db 256 DUP(?)
stack ENDS  

data SEGMENT   
welcomeMessage db "Arkanoid", 0Dh, 0Ah 
               db "The Game", 0Dh, 0Ah  
               db "Controls:", 0Dh, 0Ah
               db "Left/Right arrow - move paddle", 0Dh, 0Ah
               db "Esc - exit", 0Dh, 0Ah
               db "Enter - start", 0Dh, 0Ah, '$'
gameTitle      db "Arkanoid" 
scoreTitle     db "Score:"
comboTitle     db "Combo:"        
winMessage     db "     YOU WIN       "
               db "Thanks for playing!"
loseMessage    db "     YOU LOSE      "
               db "    Try again!     "               
yourScoreMes   db "  Your score:      "
bestScoreMes   db "  Best score:      "
newBestScore   db "  New best score!  "      
restartMess    db "Press Enter to restart"
                    
bricksLeftCounter dw 0
score dw 0 
bestScore dw 0
combo dw 0
   
nextMoveUp dw 0
prevNextMoveUp dw 0   
nextMoveRight dw 0 
                  
ballPositionY dw 0 ;ñ÷åò èç âåðõíåãî ëåâîãî óãëà (0;0)
ballPositionX dw 0

ballPrevPositionX dw 1
ballPrevPositionY dw 1  
    
paddlePosition dw 37 ;ñ÷åò ñ ëåâîãî êðàÿ (áîðäþð - -1)
paddlePrevPosition dw 0                 
previousTime dw 0   
data ENDS

code SEGMENT
main:        
    mov ax, data
    mov ds, ax
    mov ax, 0b800h
    mov es, ax
    mov ah, 00
    mov al, 03
    int 10h       
    mov ah, 9h
    lea dx, welcomeMessage
    int 21h
waitEnterWelcomeScreen:
    mov ah, 01h               
    int 16h
    jz waitEnterWelcomeScreen
    xor ah, ah
    int 16h
    cmp ah, 1Ch
    je initGame
    cmp ah, 01h
    je exitGame
    jmp waitEnterWelcomeScreen    
initGame:  
    mov bricksLeftCounter, 0  
    mov score, 0 
    mov combo, 0
    mov nextMoveUp, 1
    mov nextMoveRight, 1   
    mov ballPrevPositionX, 1
    mov ballPrevPositionY, 1
    mov paddlePrevPosition, 0
    mov previousTime, 0 
    call initScreen
    call startPaddle
    mov ah, 01h
    xor cx, cx
    xor dx, dx
    int 1Ah
startGame:
    mov ah, 01h
    int 16h
    jz gameTick
    xor ah, ah
    int 16h
    cmp ah, 4Dh
    je gameRightPressed
    cmp ah, 4Bh
    je gameLeftPressed
    cmp ah, 01h
    je exitGame
    jmp gameTick    
gameRightPressed:
    cmp paddlePosition, 73
    jge gameTick 
    mov ax, paddlePosition 
    mov paddlePrevPosition, ax 
    inc paddlePosition    
    call printPaddle        
    jmp gameTick
gameLeftPressed:
    cmp paddlePosition, 0
    je gameTick   
    mov ax, paddlePosition 
    mov paddlePrevPosition, ax 
    dec paddlePosition    
    call printPaddle
gameTick:    
    xor ax, ax
    int 1Ah
    push dx
    mov ax, previousTime
    sub dx, ax
    pop ax
    cmp dx, 3
    jl nextIteration
    mov previousTime, ax
    call moveBall
    cmp ax, 0
    je continueGame
    mov ax, 1
    call printEndMessages
    jmp waitEnter
continueGame:
    cmp bricksLeftCounter, 0
    jne nextIteration 
    mov ax, 2
    call printEndMessages
    jmp waitEnter
nextIteration:
    jmp startGame

waitEnter:
    mov ah, 01h
    int 16h
    jz waitEnter
    xor ah, ah
    int 16h
    cmp ah, 1Ch
    je initGame
    cmp ah, 01h
    je exitGame
    jmp waitEnter
      
exitGame:
    mov ah, 4Ch
    int 21h
;******************PROCEDURES**********************
;èíèöèàëèçàöèÿ èãðîâîé îáëàñòè    
initScreen PROC
    mov ah, 00
    mov al, 03
    int 10h
    
    mov ax, ' '
    mov cx, 80
    xor di, di
    mov bx, 70h
printUpperBorder:    
    call printSymbol
    loop printUpperBorder
    
    mov cx, 23
printSideBorders:
    call printSymbol
    add di, 156
    call printSymbol   
    loop printSideBorders
     
    mov cx, 80 
printBottomBorder:
    call printSymbol
    loop printBottomBorder
    
    mov di, 72
    mov cx, 8
    lea si, gameTitle
    mov bx, 74h 
printGameTitle:
    mov ax, [si]
    call printSymbol
    inc si
    loop printGameTitle
    
    mov di, 138     
    mov cx, 6
    lea si, scoreTitle
    mov bx, 70h
printScoreTitle:
    mov ax, [si]    
    call printSymbol
    inc si
    loop printScoreTitle 
    
    mov di, 3978
    mov cx, 6
    lea si, comboTitle 
    mov bx, 70h
printComboTitle:
    mov ax, [si]    
    call printSymbol
    inc si
    loop printComboTitle
    
    xor bh, bh
    mov dh, 25
    mov ah, 02
    int 10h
    
    mov di, 150
    mov ax, score
    mov si, 70h
    call printNumber
    mov di, 3990
    mov ax, combo
    mov si, 70h
    call printNumber    
    call printBricks
    call printPaddle
    mov ballPositionY, 21
    mov ax, paddlePosition
    add ax, 3
    mov ballPositionX, ax     
    call printBall

    ret
initScreen ENDP
;**************************************************
;âûâîä ñèìâîëà (ax) ñ àòðèáóòîì (bx) íà ýêðàí (es)
;ìåñòî äîëæíî áûòü óêàçàíî äî âûçîâà ôóíêöèè â di
printSymbol PROC
    mov es:[di], ax
    inc di
    mov es:[di], bx
    inc di
    ret
printSymbol ENDP
;************************************************** 
;âûâîäèò íà ýêðàí ÷èñëî èç ax, â ìåñòî di ñ àòðèáóòîì si
printNumber PROC    
    xor cx, cx
    mov bx, 10
scoreParsing:
    xor dx, dx 
    div bx  ;â dx îñòàåòñÿ ïîñëåäíÿÿ öèôðà
    push dx
    inc cx
    test ax, ax
    jnz scoreParsing ;ïîâòîðÿåì, ïîêà â ÷àñòíîì(ax) íå áóäåò 0
    
    mov bx, si
printNumberFromStack:
    pop ax
    add al, '0' ;ïåðåâåñòè â ñèìâîë
    call printSymbol 
    loop printNumberFromStack

    ret
printNumber ENDP    
;**************************************************
printBricks PROC
    mov di, 648
    mov bx, 10h
    mov ax, ' '
    mov dx, 1 
    mov cx, 8
printBricksOuterLoop:
    push cx
    mov cx, 72
printBricksInnerLoop:        
    call printSymbol
    inc bricksLeftCounter
    loop printBricksInnerLoop 
    cmp dx, 0
    je printBricksNextColor
    dec dx
    jmp printBricksScipChange
printBricksNextColor:    
    add bx, 10h
    mov dx, 1
printBricksScipChange:
    add di, 16
    pop cx
    loop printBricksOuterLoop

    ret
printBricks ENDP
;**************************************************
;çàêðàøèâàåò ïðåäûäóùåå ïîëîæåíèå ìÿ÷à è ðèñóåò íîâîå
printBall PROC
    mov ax, ballPrevPositionY
    mov bx, 160
    mul bl
    mov dx, ax
    mov ax, ballPrevPositionX
    mov bx, 2
    mul bl
    add ax, dx
    mov di, ax
    mov ax, ' '
    mov bx, 00h
    call printSymbol
    mov ax, ballPositionY
    mov bx, 160
    mul bl
    mov dx, ax
    mov ax, ballPositionX
    mov bx, 2
    mul bl
    add ax, dx
    mov di, ax
    mov ax, ' '
    mov bx, 70h
    call printSymbol
    ret
printBall ENDP
;**************************************************
;çàêðàøèâàåò ïðåäûäóùåå ïîëîæåíèå ðàêåòêè è ðèñóåò íîâîå
printPaddle PROC
    mov di, 3522 
    mov ax, paddlePrevPosition
    mov dx, 2
    mul dl
    add di, ax
    mov ax, ' '
    mov bx, 00h 
    mov cx, 5
clearPaddleLineLoop:
    call printSymbol
    loop clearPaddleLineLoop    
    mov di, 3522
    mov ax, paddlePosition
    mov dx, 2
    mul dl
    add di, ax
    mov ax, ' '
    mov bx, 60h
    mov cx, 5
printPaddleLoop:
    call printSymbol    
    loop printPaddleLoop
    
    ret
printPaddle ENDP
;**************************************************
;<- 4Bh
;-> 4Dh
;Enter 1Ch
;Esc 01h 
;ïåðåìåùåíèå ðàêåòêè äî ñòàðòà øàðà
startPaddle PROC
startPaddleLoop:
    mov ah, 01h
    int 16h
    jz startPaddleLoop
    xor ah, ah
    int 16h
    cmp ah, 4Dh
    je startRightPressed
    cmp ah, 4Bh
    je startLeftPressed
    cmp ah, 1Ch
    je startEnterPressed
    cmp ah, 01h
    je exitGame
    jmp startPaddleLoop
startRightPressed:
    cmp paddlePosition, 73
    jge startPaddleLoop 
    mov ax, paddlePosition 
    mov paddlePrevPosition, ax 
    inc paddlePosition
    mov ax, ballPositionX
    mov ballPrevPositionX, ax
    mov ballPrevPositionY, 21
    inc ballPositionX
    call printPaddle
    call printBall
    jmp startPaddleLoop
startLeftPressed:
    cmp paddlePosition, 0
    je startPaddleLoop
    mov ax, paddlePosition 
    mov paddlePrevPosition, ax 
    dec paddlePosition
    mov ax, ballPositionX
    mov ballPrevPositionX, ax
    mov ballPrevPositionY, 21
    dec ballPositionX
    call printPaddle
    call printBall
    jmp startPaddleLoop
startEnterPressed:
    ret
startPaddle ENDP
;************************************************** 
;Âîçâðàùàåìûå çíà÷åíèÿ:
;ax = 00h âñå õîðîøî
;ax = 01h ïðîèãðûø
moveBall PROC
    mov ax, ballPositionY
    mov ballPrevPositionY, ax
    mov ax, ballPositionX
    mov ballPrevPositionX, ax
    mov ax, nextMoveUp
    mov prevNextMoveUp, ax
    
    cmp nextMoveUp, 1
    jne tryMoveDown
    ;tryMoveUp
    mov ax, ballPositionY
    dec ax
    cmp ax, 0
    ja moveUp
UpBrickHit:
    mov nextMoveUp, 0
    inc ballPositionY
    jmp moveXAxis
moveUp:
  mov bx, ballPositionX  
  call checkBrickHit
  cmp dx, 1
  je UpBrickHit    
    dec ballPositionY
    jmp moveXAxis
tryMoveDown:
    mov ax, ballPositionY
    inc ax
    cmp ax, 24 
    jb moveDown
    ;ïðîèãðûø
    mov ax, 01h
    ret
moveDown:
  mov bx, ballPositionX  
  call checkBrickHit
  cmp dx, 0
  je noDownBrickHit 
  mov nextMoveUp, 1
  dec ballPositionY
  jmp moveXAxis
noDownBrickHit:  
    cmp ax, 22
    je checkPaddleHit
    inc ballPositionY
    jmp moveXAxis
checkPaddleHit:
    mov ax, paddlePosition
    inc ax
    cmp ax, ballPositionX
    ja paddleMiss
    add ax, 4
    cmp ax, ballPositionX
    jb paddleMiss
    mov combo, 0
    mov di, 3990
    mov ax, combo
    mov si, 70h
    call printNumber
    mov nextMoveUp, 1
    dec ballPositionY
    jmp moveXAxis
paddleMiss:
    inc ballPositionY
    jmp moveXAxis



    
moveXAxis:
    cmp nextMoveRight, 1
    jne tryMoveLeft
    ;tryMoveRight
    mov bx, ballPositionX
    inc bx
    cmp bx, 79
    jb moveRight     
    mov nextMoveRight, 0
    dec ballPositionX
    jmp move
moveRight:
    mov ax, ballPrevPositionY
    cmp prevNextMoveUp, 0
    je noDecAXRight
    dec ax
noDecAXRight:
    cmp ax, 0
    jne notUpperBorderRight
    inc ballPositionX
    jmp move
notUpperBorderRight:
    cmp ballPrevPositionY, 21
    jae checkPaddleMissLeft
    jmp checkBricksRight
checkPaddleMissLeft:
    mov cx, paddlePosition
    inc cx
    cmp bx, cx
    je paddleMissXLeft
    inc ballPositionX
    jmp move
paddleMissXLeft:
    cmp ballPrevPositionY, 21
    je move
    cmp ballPrevPositionY, 22
    je paddleBorderHitLeft
    inc ballPositionX
    jmp move
paddleBorderHitLeft:    
    mov nextMoveRight, 0
    dec ballPositionX
    jmp move
checkBricksRight:
  mov ax, ballPrevPositionY
  call checkBrickHit
  cmp dx, 1
  je rightBrickHit 
  inc ballPositionX
  jmp noRightBrickHit
rightBrickHit:   
  mov nextMoveRight, 0
  dec ballPositionX
noRightBrickHit: 
  mov ax, ballPrevPositionY
  mov bx, ballPrevPositionX
  inc bx
  cmp prevNextMoveUp, 0
  je incAX
  dec ax
  jmp callCheck
incAX:
  inc ax
callCheck:  
  call checkBrickHit
  jmp move 
  
  
tryMoveLeft:    
    mov bx, ballPositionX
    dec bx
    cmp bx, 0
    ja moveLeft    
    mov nextMoveRight, 1
    inc ballPositionX
    jmp move
moveLeft:
    mov ax, ballPrevPositionY
    cmp prevNextMoveUp, 0
    je noDecAXLeft
    dec ax
noDecAXLeft:
    cmp ax, 0
    jne notUpperBorderLeft
    dec ballPositionX
    jmp move
notUpperBorderLeft:    
    cmp ballPrevPositionY, 21
    jae checkPaddleMissRight
    jmp checkBricksLeft
checkPaddleMissRight:
    mov cx, paddlePosition
    add cx, 5
    cmp bx, cx
    je paddleMissXRight
    dec ballPositionX
    jmp move
paddleMissXRight:    
    cmp ballPrevPositionY, 21
    je move
    cmp ballPrevPositionY, 22
    je paddleBorderHitRight
    dec ballPositionX
    jmp move   
paddleBorderHitRight:    
    mov nextMoveRight, 1
    inc ballPositionX
    jmp move  
checkBricksLeft:
  mov ax, ballPrevPositionY
  call checkBrickHit
  cmp dx, 1
  je leftBrickHit
  dec ballPositionX
  jmp noLeftBrickHit
leftBrickHit:
  mov nextMoveRight, 1
  inc ballPositionX
noLeftBrickHit:
  mov ax, ballPrevPositionY 
  mov bx, ballPrevPositionX
  dec bx
  cmp prevNextMoveUp, 0
  je incAXLeft
  dec ax
  jmp callCheckLeft
incAXLeft:
  inc ax
callCheckLeft:  
  call checkBrickHit
  jmp move
    
move:
    call printBall
    mov ax, 0
    ret
moveBall ENDP
;**************************************************  
;Âõîäíûå ïàðàìåòðû:
;ax - ballPositionY
;bx - ballPositionX
;Âûõîäíûå ïàðàìåòðû:
;dx = 0 - íå áûëî ñòîëêíîâåíèÿ
;dx = 1 - áûëî ñòîëêíîâåíèå 
checkBrickHit PROC
    cmp ax, 21
    jb abovePaddle
    mov dx, 0
    ret
abovePaddle:    
    mov dx, 160
    mul dl
    mov cx, ax
    mov ax, bx
    mov dx, 2
    mul dl
    add ax, cx
    mov di, ax
    inc di
    mov ax, es:[di]
    cmp al, 10h
    jae brickFound
    mov dx, 0
    ret
brickFound:
    dec di
    mov ax, ' '
    mov bx, 0
    call printSymbol
    inc combo
    dec bricksLeftCounter
    add score, 10
    mov ax, combo
    add score, ax
    mov di, 150
    mov ax, score
    mov si, 70h
    call printNumber
    mov di, 3990
    mov ax, combo
    mov si, 70h
    call printNumber
    mov dx, 1    
    ret
checkBrickHit ENDP
;**************************************************
;ax = 1 - ïðîèãðûø
;ax = 2 - ïîáåäà
printEndMessages PROC
    xor dx, dx
    mov bx, score
    cmp bx, bestScore
    jbe printMessage
    mov dx, 1
    mov bestScore, bx 
printMessage:
    mov di, 1822
    mov cx, 19
    mov bx, 75h
    
    cmp ax, 1
    je printLose
    
    lea si, winMessage
printWin1:
    mov ax, [si]
    call printSymbol
    inc si
    loop printWin1
    
    add di, 122      
    mov cx, 19
printWin2:
    mov ax, [si]
    call printSymbol
    inc si
    loop printWin2
    jmp nextMessage
    
printLose:    
    lea si, loseMessage
printLose1:
    mov ax, [si]
    call printSymbol
    inc si
    loop printLose1
    
    add di, 122      
    mov cx, 19
printLose2:
    mov ax, [si]
    call printSymbol
    inc si
    loop printLose2

nextMessage:    
    add di, 122      
    mov cx, 19        
    cmp dx, 0
    je printScore
    lea si, newBestScore
printNewBestScore:
    mov ax, [si]
    call printSymbol
    inc si
    loop printNewBestScore
    jmp pressEnterToRestart
printScore:
    lea si, yourScoreMes
printYourScore:
    mov ax, [si]
    call printSymbol
    inc si
    loop printYourScore 
    
    sub di, 10
    mov ax, score
    mov si, 75h
    call printNumber
    
    mov di, 2302      
    mov cx, 19
    mov bx, 75h
    lea si, bestScoreMes
printBestScore:          
    mov ax, [si]
    call printSymbol
    inc si
    loop printBestScore
    
    sub di, 10
    mov ax, bestScore
    mov si, 75h
    call printNumber 
    
pressEnterToRestart:
    mov di, 2460
    mov cx, 22
    mov bx, 75h
    lea si, restartMess 
pressEnter:
    mov ax, [si]
    call printSymbol
    inc si
    loop pressEnter    
    
    ret
printEndMessages ENDP
;**************************************************    
    end main
code Ends    
