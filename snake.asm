[bits 16]
[org 0x7C00]

BORDER_CHAR     equ '@'
BORDER_HEIGHT   equ 24
BORDER_WIDTH    equ 40

start:
    xor ax, ax
    mov ds, ax
    mov al, 0x13
    int 0x10

draw_border:
    xor bx, bx
    mov bl, 0x0F
    mov al, BORDER_CHAR

top:
    xor dx, dx
    mov ah, 2
    int 0x10
    mov cx, BORDER_WIDTH
    call print_width

bottom:
    mov dh, BORDER_HEIGHT - 1
    mov ah, 2
    int 0x10
    mov cx, BORDER_WIDTH
    call print_width

left:
    mov dh, BORDER_HEIGHT - 1
    mov dl, 0
    call print_height

right:
    mov dh, BORDER_HEIGHT - 1
    mov dl, BORDER_WIDTH - 1
    call print_height

    hlt
    jmp $

print_width:
    mov ah, 0x0E
    int 0x10
    dec cx
    jnz print_width
    ret

print_height:
    mov ah, 2
    int 0x10
    mov ah, 0x0E
    int 0x10
    dec dh
    jnz print_height
    ret

signature:
    times 510 - ($ - $$) db 0
    dw 0xAA55