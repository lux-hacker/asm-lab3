bits	64
; Read text from file
; Remove word, which's the first letter doesn't match with the first letter of the first word
section	.data
err1:
	db "Usage: "
err1len	equ	$-err1
err2:
	db " filename", 10
err2len	equ	$-err2
section	.text
global _start
_start:
	cmp	dword [rsp], 2 ; Сравнили, что программу запустили с двумя параметрами (первый - имя программы, второй - исходный файл). RSP - верхушка стека
	je	m3 ; если два параметра, то все ОК
	mov	eax, 1 ; вывод в поток
	mov	edi, 2 ; что в поток ошибок
	mov	esi, err1 ; сообщение
	mov	edx, err1len ; длина сообщения
	syscall
	mov	eax, 1 ; вывод в поток 
	mov	edi, 2 ; поток ошибок
	mov	rsi, [rsp+8] ; в rsp+8 лежит адрес первого параметра запуска (это строка)
	xor	edx, edx
m1:
	cmp	byte [rsi+rdx], 0
	je	m2
	inc	edx
	jmp	m1
m2:
	syscall
	mov	eax, 1
	mov	edi, 2
	mov	esi, err2
	mov	edx, err2len
	syscall
	jmp m4
m3:
	mov	rdi, [rsp+16]
	call	work
	mov	edi, eax
	jmp	m5
m4:
	mov edi, 1
m5:
	mov	eax, 60
	syscall

size	equ	1024
buf	equ	size
answer	equ buf+size
filename	equ	answer+8
fd	equ	filename+4
l 	equ fd+4 ; номер буквы в слове
n 	equ l+4 ; номер cлова
c 	equ n+4 ; первая буква строки
work:
	push	rbp
	mov	rbp, rsp
	sub	rsp, c
	mov [rbp-filename], rdi
	
	mov eax, 2
	xor esi, esi
	syscall

	or eax, eax
	mov [rbp-fd], eax
	jge .m0
	
	mov	edi, eax
	push	rax
	call writeerr
	pop rax
	jmp	.exit
.m0:
	mov	dword [rbp-l], 0
	mov	dword [rbp-n], 0
	mov	dword [rbp-c], 0
	xor	r8d, r8d
.m1:
	mov	eax, 0
	mov edi, [rbp-fd]
	lea rsi, [rbp-buf]
	mov	edx, size
	syscall
	or	eax, eax
	jle	.exit
	mov	ebx, [rbp-l]
	mov	edx, [rbp-n]
	mov	r9d, [rbp-c]
	lea rsi, [rbp-buf]
	lea rdi, [rbp-answer]
	mov	ecx, eax
.m2:
	mov	al, [rsi]
	inc rsi
	cmp al, 10
	je .m5
	cmp	al, ' '
	je	.m5
	cmp	al, 9
	je .m5
	or	edx, edx
	jne	.m3
	or	ebx, ebx
	jne	.m9
	mov	r9b, al 
.m3:
	or	ebx, ebx
	jne .m9
	mov	r8b, al
.m9:
	cmp	r8b, r9b
	jne	.m4
	or	edx, edx
	je	.m10
	or	ebx, ebx
	jne .m10
	mov	byte [rdi], ' '
	inc rdi
.m10:
	mov	[rdi], al
	inc	rdi
.m4:
	inc ebx
	jmp	.m7
.m5:
	or	ebx, ebx
	je	.m6
	xor	ebx, ebx
	inc	edx
.m6:
	cmp	al, 10
	jne	.m7
	xor	edx, edx
	mov	byte [rdi], 10
	inc rdi
.m7:
	loop	.m2
.print:
	mov	[rbp-l], ebx
	mov	[rbp-n], edx
	mov [rbp-c], r9b
	lea rsi, [rbp-answer]
	mov	rbx, rdi
	sub	rbx, rsi
	mov	edx, ebx
.m8:
	mov	eax, 1
	mov	edi, 1
	syscall
	or	eax, eax
	jl 	.exit
	sub	ebx, eax
	je	.m1
	lea rsi, [rbp+rax-answer]
	mov	edx, ebx
	jmp	.m8
.exit:
	leave
	xor eax, eax
	ret


section .data
nofile:
	db	"No such file or directory", 10
nofilelen	equ	$-nofile
permission:
	db	"Permission denied", 10
permissionlen	equ $-permission
unknown:
	db "Unknown error", 10
unknownlen	equ $-unknown

section	.text
writeerr:
	cmp edi, -2
	jne	.m1
	mov	esi, nofile
	mov	edx, nofilelen
	jmp	.m3
.m1:
	cmp edi, -13
	jne	.m2
	mov	esi, permission
	mov	edx, permissionlen
	jmp	.m3
.m2:
	mov	esi, unknown
	mov edx, unknownlen
.m3:
	mov	eax, 1
	mov	edi, 2
	syscall
	ret
