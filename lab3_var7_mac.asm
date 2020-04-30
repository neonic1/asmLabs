;������ ������ ����� ����� ������������ 30 ���������. ����� �������� ����� ������������� �����
.model small
stack SEGMENT STACK
    db 256 DUP(?)
stack ENDS
  
NULL EQU 0 
MIN_ARRAY_SIZE EQU 1              
MAX_ARRAY_SIZE EQU 30
NUMBER_MAX_LENGTH EQU 6 
                   
data SEGMENT 
    heap_empty_str db "No more free memory left.$", 0ah, 0dh 
    number_str db 0ah, 0dh, "Number: $"
    entries_str db " Number of entries: $"
    input_array_size_str_1 db 0ah, 0dh, "Please input array size ($"
    input_array_size_str_2 db " - $"
    input_array_size_str_3 db "): $"
    input_number_str_1 db 0ah, 0dh, "Input $"
    input_number_str_2 db " number: $"
    error_input db 0ah, 0dh, "Incorrect input, please try again.$"
    input_limits_str db 0ah, 0dh, "Input limits: from -32767 to 32767.$";���������� � 15 ��������          
    rand_or_hand_input_str db 0ah, 0dh, "1. Fill array with random numbers.", 0ah, 0dh, "2. Fill array manually.", 0ah, 0dh, "Your choice: $"         
    common_number_str db 0ah, 0dh, "Most commonly seen number(s): $"
    repeat_common_number_str db ", $"
    off_init_heap dw ?
    seg_init_heap dw ? 
    off_dispose dw ?
    seg_dispose dw ?
    off_new dw ?
    seg_new dw ?
    spis_size dw 0 
    array_size dw ?
    input_buff_max db NUMBER_MAX_LENGTH+1
    input_buff_length db '$'
    input_buff db NUMBER_MAX_LENGTH+2 dup('$')
    seed dw -1
    rnd_max dw 200
    array dw MAX_ARRAY_SIZE dup(?)
    sort_ms dw 6 dup(?)         
data ENDS

heap SEGMENT
    heap_ptr dw ?   ;������ �� ������ ����� ���
    dw MAX_ARRAY_SIZE*3 dup(?)
    list dw NULL    ;������ �� ������ ����� ������ 
;******************PROCEDURES**********************
;������������� ���(������ ��������� ������)
init_heap PROC far
    push si
    push bx
    push cx
;����������� ���    
    mov cx, MAX_ARRAY_SIZE
    mov bx, NULL      ;bx - ����� ���������� ��������
    mov si, 6*MAX_ARRAY_SIZE   ;si ��������� �� ��������� ��� ����� ���
INIT:
    mov es:[si], bx   ;���������� � ��������� ��� ����� ����� ����� ����. �����
    sub si, 4
    mov bx, si
    sub si, 2
    loop INIT
    mov es:heap_ptr, bx  ;heap_ptr ��������� �� ������ ���

    pop cx
    pop bx
    pop si
    ret
init_heap ENDP
;**************************************************
;�������� ����� di �� ������ � ��������� � ������ ��� 
dispose PROC far     
    push bx 
    push ax      
    add di, 4
    mov bx, es:[di]
    sub di, 6
    mov es:[di], bx
    add di, 6
    mov ax, es:heap_ptr
    mov es:[di], ax
    sub di, 4
    mov es:heap_ptr, di 
    pop ax
    pop bx 
    ret
dispose ENDP
;**************************************************
;��������� �� ������ ��� ����� � ���������� ��� ����� � di
new PROC far     
    push bx
    mov di, es:heap_ptr
    cmp di, NULL
    je HEAP_EMPTY
    add di, 4
    mov bx, es:[di]
    sub di, 4
    mov es:heap_ptr, bx
    pop bx
    ret
HEAP_EMPTY:
    lea dx, heap_empty_str 
    mov ah, 09h
    int 21h
    pop bx
    ret
new ENDP 
;**************************************************  
heap ENDS

code SEGMENT
;**************************************************
;��������� ���������� ��������
;�����: ����� � ax
get_random_number MACRO
    LOCAL SEED_INITIALIZED      
    push dx
    mov ah, 00h
    int 1Ah
    mov ax, dx 
    cmp seed, -1
    jne SEED_INITIALIZED
    mov seed, 13532 
SEED_INITIALIZED:
    mul seed
    xor dx, dx
    div rnd_max
    mov ax, dx     ;������� �� ������� � ax
    mov seed, ax 
    pop dx           
ENDM      
;************************************************** 
    start:
    mov ax, data
    mov ds, ax
    mov ax, heap
    mov es, ax
    xor ax, ax
    
    mov off_init_heap, init_heap
    mov seg_init_heap, seg init_heap
    mov off_dispose, dispose
    mov seg_dispose, seg dispose
    mov off_new, new
    mov seg_new, seg new
    
    call far off_init_heap
    
    ;���� ������� �������
INPUT_ARRAY_SIZE:    
    lea dx, input_array_size_str_1
    call print_str
    mov ax, MIN_ARRAY_SIZE
    call print_number
    lea dx, input_array_size_str_2
    call print_str
    mov ax, MAX_ARRAY_SIZE
    call print_number
    lea dx, input_array_size_str_3
    call print_str     
    push MIN_ARRAY_SIZE
    push MAX_ARRAY_SIZE
    call enter_number
    add sp, 4
    cmp di, 2
    jnz INPUT_ARRAY_SIZE_NO_ERROR
    lea dx, error_input
    call print_str
    jmp INPUT_ARRAY_SIZE
INPUT_ARRAY_SIZE_NO_ERROR:
    mov array_size, ax
    
    ;����� ������� �����
INPUT_TYPE:     
    lea dx, rand_or_hand_input_str
    call print_str
    push 1
    push 2
    call enter_number
    add sp, 4
    cmp di, 2
    jnz INPUT_TYPE_NO_ERROR
    lea dx, error_input
    call print_str
    jmp INPUT_TYPE
INPUT_TYPE_NO_ERROR:    
    cmp ax, 1
    je RANDOM_INPUT
    
    ;���� ����� �������
    lea dx, input_limits_str
    call print_str 
    lea si, array
    xor cx, cx
INPUT_ARRAY:
    cmp cx, array_size
    je END_INPUT
    lea dx, input_number_str_1
    call print_str
    mov ax, cx
    inc ax
    call print_number   
    lea dx, input_number_str_2
    call print_str
    push cx
    push si
    push 0
    call enter_number
    add sp, 2
    pop si
    pop cx
    cmp di, 2
    jnz INPUT_ARRAY_NO_ERROR
    lea dx, error_input
    call print_str
    jmp INPUT_ARRAY
INPUT_ARRAY_NO_ERROR:
    mov [si], ax
    inc cx
    add si, 2
    jmp INPUT_ARRAY    
END_INPUT:
    jmp PROCESSING
    
    ;���� ����� ��������
RANDOM_INPUT:    
    xor cx, cx
    lea si, array
RANDOM_INPUT_ARRAY:
    cmp cx, array_size
    je END_RANDOM_INPUT
    push cx
    get_random_number
RANDOM_INPUT_CYCLE: 
    loop RANDOM_INPUT_CYCLE
    pop cx
    mov [si], ax
    inc cx
    add si, 2
    jmp RANDOM_INPUT_ARRAY  
END_RANDOM_INPUT:    
    
    ;�������� ������ �� �������
    ;����� ������: �����|���������� ��������� � �������|������ �� ����. �������
PROCESSING:    
    mov cx, array_size
    mov si, 0
MAKE_SPIS:
    mov di, es:list
    mov ax, array[si]
NEXT_SPIS_ELEM:
    cmp di, NULL
    je MAKE_NEW_SPIS_ELEM
    cmp es:[di], ax 
    jne NO_MATCH
    je MATCH 
NO_MATCH:     
    add di, 4 
    mov di, es:[di]
    jmp NEXT_SPIS_ELEM 
MATCH:     
    add di, 2
    inc es:[di]
    jmp NEXT_NUMBER
MAKE_NEW_SPIS_ELEM:
    call far off_new
    inc spis_size
    mov es:[di], ax
    add di, 2
    mov es:[di], 1
    add di, 2
    mov ax, es:list
    mov es:[di], ax
    sub di, 4
    mov es:list, di
NEXT_NUMBER: 
    add si, 2
    loop MAKE_SPIS
    
    ;���������� ������
    xor cx, cx
SORT_START:
    cmp cx, 0
    jne PREV_ELEM
    ;���������� (list)
    mov ax, es:list
    mov sort_ms[0], ax 
    lea ax, list
    mov sort_ms[2], ax
    mov di, es:list
    jmp CUR_ELEM
PREV_ELEM:
    ;����������
    pop di
    add di, 4
    mov ax, es:[di]
    mov sort_ms[0], ax
    mov sort_ms[2], di
    mov di, es:[di]
CUR_ELEM:   
    ;�������
    push di
    add di, 2
    mov dx, es:[di]
    add di, 2 
    mov ax, es:[di]
    mov sort_ms[4], ax
    mov sort_ms[6], di       
    mov di, es:[di] 
    ;��������� 
    cmp di, NULL
    je SORT_END
    add di, 2
    mov bx, es:[di]
    add di, 2 
    mov ax, es:[di]
    mov sort_ms[8], ax
    mov sort_ms[10], di
    ;���������
    cmp dx, bx
    jnl NOT_LESS
    ;�������� ������� ������� � ���������
    mov ax, sort_ms[4] 
    mov di, sort_ms[2] 
    mov es:[di], ax
    mov ax, sort_ms[8]
    mov di, sort_ms[6] 
    mov es:[di], ax
    mov ax, sort_ms[0]
    mov di, sort_ms[10] 
    mov es:[di], ax 
    
    xor cx, cx
    jmp SORT_START
NOT_LESS:
    inc cx
    jmp SORT_START
SORT_END:
    
    ;����� �������� ����� �������������� �����
    lea dx, common_number_str
    call print_str
    mov di, es:list
    mov ax, es:[di]
    add di, 2
REPEAT_COMMON_OUTPUT:
    call print_number
    mov bx, es:[di]
    add di, 2
    mov di, es:[di]
    cmp di, NULL
    je DONT_REPEAT_COMMON_OUTPUT
    mov ax, es:[di]
    add di, 2
    mov dx, es:[di]
    cmp bx, dx
    jne DONT_REPEAT_COMMON_OUTPUT 
    push ax
    lea dx, repeat_common_number_str
    call print_str 
    pop ax
    jmp REPEAT_COMMON_OUTPUT  
DONT_REPEAT_COMMON_OUTPUT:
    
    ;����� ���������������� ������
    mov di, es:list      
PRINT_SPIS:
    cmp di, NULL
    je END
    lea dx, number_str
    call print_str
    mov ax, es:[di]
    call print_number
    add di, 2
    lea dx, entries_str
    call print_str
    mov ax, es:[di]
    call print_number
    add di, 2
    mov di, es:[di]      
    jmp PRINT_SPIS      
END:          

    mov ah, 4ch
    int 21h
      
;******************PROCEDURES**********************
;����� ������ �� dx �� �����    
print_str PROC
    mov ah, 09h
    int 21h
    ret
print_str ENDP
;**************************************************      
;����� ����� �� ax �� �����      
print_number PROC 
   push bx
   push cx
   push dx
   
   test ax, ax
   jns OUTPUT_POSITIVE_NUMBER ;���� ����� �������������
   ;������� ����� � ������� ��� ������
   mov cx, ax
   mov ah, 02h
   mov dl, '-'
   int 21h
   mov ax, cx
   neg ax
   ;� cx ���������� ���� � �����
OUTPUT_POSITIVE_NUMBER:  
    xor cx, cx
    mov bx, 10
OUTPUT_LOOP:
    xor dx, dx 
    div bx    ;� dx �������� ��������� �����
    push dx
    inc cx
    test ax, ax
    jnz OUTPUT_LOOP    ;���������, ���� � �������(ax) �� ����� 0

    ;������� �����
    mov ah, 02h
OUTPUT__FROM_STACK:
    pop dx
    add dl, '0' ;��������� � ������
    int 21h
    loop OUTPUT__FROM_STACK
    
    pop dx
    pop cx
    pop bx
    ret
print_number ENDP     
;************************************************** 
;���� ����� � ax
;����:  ����: ����.��������         ��� ������������� ���������(-32767 to 32767):
;             ���.��������                              ����: 0
;             ...                             ����� ������: add sp, 2 
;����� ������ �� ��������� add sp, 4
;���� di==2 - ��������� ������ �����   
enter_number PROC
    push bp 
    lea dx, input_buff_max 
    mov ah, 0ah
    int 21h
    cmp input_buff_length, 0
    je INPUT_ERROR
    xor di, di
    xor si, si
    lea si, input_buff 
    cmp byte ptr [si], "-" ;���� ������ ������ �����
    jnz INPUT_POSITIVE_NUMBER
    mov di, 1 
    inc si
INPUT_POSITIVE_NUMBER:
    xor ax, ax
    xor bx, bx
    xor cx, cx
    mov bx, 10  ;��
INPUT_LOOP:
    mov cl, [si]
    cmp cl, 0dh
    jz INPUT_CHECK_BORDERS    ;���� cl == CR
    cmp cl, '0'  ;���� < 0
    jb INPUT_ERROR
    cmp cl, '9'  ;���� > 9
    ja INPUT_ERROR
 
    sub cl, '0' ;�� ������� � �����
    mul bx      ;�������� ax �� 10
    jo INPUT_ERROR
    jc INPUT_ERROR
    add ax, cx  ;���������� � ���������
    jo INPUT_ERROR
    jc INPUT_ERROR
    inc si 
    jmp INPUT_LOOP      
INPUT_ERROR: 
    mov di, 2
    pop bp
    ret
INPUT_CHECK_BORDERS:
    cmp di, 1 ;���� di==1 ������ ����� �������������
    jnz INPUT_POSITIVE_CHECK
    neg ax
    jns INPUT_ERROR
    jmp INPUT_NEXT_CHECK   
INPUT_POSITIVE_CHECK:     
    test ax, ax
    js INPUT_ERROR 
INPUT_NEXT_CHECK:
    mov bp, sp
    mov bx, [bp+4]
    cmp bx, 0
    je INPUT_END
    cmp ax, bx
    jg INPUT_ERROR 
    xor bx, bx
    mov bx, [bp+6]
    cmp ax, bx
    jl INPUT_ERROR
INPUT_END:    
    pop bp
    ret  
enter_number ENDP      
;**************************************************     
    end start
code ENDS