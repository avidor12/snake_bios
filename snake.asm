[bits 16]
[org 0x7C00]

BORDER_CHAR             equ '@'
BORDER_HEIGHT           equ 24
BORDER_WIDTH            equ 40

BLANK_CHAR              equ ' '
SNAKE_CHAR              equ '*'
SNAKE_INITIAL_LENGTH    equ 5
SNAKE_INITIAL_X         equ 20
SNAKE_INITIAL_Y         equ 10

FRUIT_CHAR              equ '$'

CLOCK_ADDRESS           equ 0x46C

start:
    xor ax, ax
    mov ds, ax
    mov al, 0x13
    int 0x10

    mov al, 0xff
    out 0x40, al
    out 0x40, al

    mov bp, 0x7ff0         ; Stack base
    mov sp, 0x7ff0         ; Stack pointer

draw_border:
    xor bx, bx
    mov bl, 0x0F
    mov al, BORDER_CHAR

.top:
    xor dx, dx
    mov ah, 2
    int 0x10
    mov cx, BORDER_WIDTH
    call .print_width

.bottom:
    xor dx, dx
    mov dh, BORDER_HEIGHT - 1
    mov ah, 2
    int 0x10
    mov cx, BORDER_WIDTH
    call .print_width

.left:
    mov dh, BORDER_HEIGHT - 1
    mov dl, 0
    call .print_height

.right:
    mov dh, BORDER_HEIGHT - 1
    mov dl, BORDER_WIDTH - 1
    call .print_height

    jmp reset_stack

.print_width:
    mov ah, 0x0E
    int 0x10
    dec cx
    jnz .print_width
    ret

.print_height:
    mov ah, 2
    int 0x10
    mov ah, 0x0E
    int 0x10
    dec dh
    jnz .print_height
    ret

reset_stack:
    mov bp, 0x9ff0         ; Stack base
    mov sp, 0x9ff0         ; Stack pointer

snake_init:
    mov dh, SNAKE_INITIAL_Y
    mov dl, SNAKE_INITIAL_X
    mov ah, 2
    int 0x10
    mov al, SNAKE_CHAR
    mov cx, SNAKE_INITIAL_LENGTH

.snake_draw:
    mov ah, 0x0E
    int 0x10
    push dx
    inc dx
    dec cx
    jnz .snake_draw

    call spawn_fruit
game_loop:

    mov al, [CLOCK_ADDRESS]
.tick:
    cmp al, [CLOCK_ADDRESS]
    je .tick

    mov ah, 1
    int 0x16
    jnz .key_pressed
    jmp [.default_direction]

.key_pressed:
    xor ax, ax
    int 0x16

    cmp ax, [.up_arrow]
    je .up
    cmp ax, [.down_arrow]
    je .down
    cmp ax, [.left_arrow]
    je .left
    cmp ax, [.right_arrow]
    je .right

.up:
    cmp word [.default_direction], .down
    je .down
    mov word [.default_direction], .up
    pop dx
    push dx
    dec dh
    jmp .set

.down:
    cmp word [.default_direction], .up
    je .up
    mov word [.default_direction], .down
    pop dx
    push dx
    inc dh
    jmp .set

.left:
    cmp word [.default_direction], .right
    je .right
    mov word [.default_direction], .left
    pop dx
    push dx
    dec dl
    jmp .set

.right:
    cmp word [.default_direction], .left
    je .left
    mov word [.default_direction], .right
    pop dx
    push dx
    inc dl
    jmp .set

.set:
    cmp dh, 0
    je .stop
    cmp dh, BORDER_HEIGHT - 1
    je .stop
    cmp dl, 0
    je .stop
    cmp dl, BORDER_WIDTH - 1
    je .stop
    push dx
    xor bx, bx
    mov ah, 2
    int 0x10

    mov bl, 0x0F
    mov al, SNAKE_CHAR
    mov ah, 0x0E
    int 0x10

    cmp dx, [fruit_pos]
    jne .no_fruit
    call spawn_fruit
    jmp game_loop

.no_fruit:
    sub bp, 2
    mov dx, [bp]
    xor bx, bx
    mov ah, 2
    int 0x10

    mov bl, 0x0F
    mov al, BLANK_CHAR
    mov ah, 0x0E
    int 0x10
    jmp game_loop

.stop:
    hlt
    jmp $

.up_arrow            dw 0x4800
.down_arrow          dw 0x5000
.left_arrow          dw 0x4B00
.right_arrow         dw 0x4D00
.default_direction   dw .right

spawn_fruit:
    call lfsr_next
    xor dx, dx
    mov bx, BORDER_WIDTH - 2
    div bx
    mov cl, dl
    inc cl

    call lfsr_next
    xor dx, dx
    mov bx, BORDER_HEIGHT - 2
    div bx
    mov dh, dl
    inc dh
    mov dl, cl

    mov [fruit_pos], dx
    xor bx, bx
    mov ah, 2
    int 0x10
    mov bl, 0x0F
    mov al, FRUIT_CHAR
    mov ah, 0x0E
    int 0x10
    ret

lfsr_next:
    mov ax, [.lfsr_state]
    shr ax, 1
    jnc .store
    xor ax, 0xB400
.store:
    mov [.lfsr_state], ax
    ret

.lfsr_state dw 0xACE1

fruit_pos dw 0

signature:
    times 510 - ($ - $$) db 0
    dw 0xAA55