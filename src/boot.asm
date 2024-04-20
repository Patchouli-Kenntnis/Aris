org 0x7C00 ; BIOS loads boot sector to 0x7C00
bits 16 ; 16 bit mode
%define ENDL 0x0D, 0x0A ; new line characters
hex_buffer: db '0x0000', 0 ; buffer to store hex string


start:
	jmp main ; jump to main





; print string
; Input: SI = pointer to string
; Output: None
;
print:
	pusha ; save registers
.loop:
	lodsb ; load byte from [SI] to AL and increment SI
	or al, al ; check if AL is 0 (end of string)
	jz .done ; if AL is 0, jump to done

	mov ah, 0x0E ; teletype output
	int 0x10 ; call BIOS interrupt

    jmp .loop ; loop

.done:
	popa ; restore registers
	ret ; return

; print hex value 
; Input: DX = value to print
; Output: None
;
print_hex:
	pusha
	mov bx, hex_buffer ; store pointer to hex value
	add bx, 0x5     ; move pointer to end of string

loop:
	mov cl, dl  ; copy dx  value into cl
	cmp cl, 0   ; check if 0
	je end_loop ; if 0 then we're done

	and cl, 0xF ; mask first half byte
	cmp cl, 0xA ; compare to A
	jl lt_A     ; if <  A go to lt_A
	jmp gte_A   ; if >= A go to gte_A

lt_A: ; add 48 
	add cl, 48  ; add 48 to bring it to ascii '0'
	jmp end_cmp ; go to end of this code block
gte_A: ; add 55
	add cl, 55  ; add 55 to bring it to ascii 'A'
	jmp end_cmp ; go to end of this code block

end_cmp:
	mov [bx], cl  ; put value into dereferenced pointer
	sub bx, 1     ; decrement pointer
	shr dx, 4     ; shift right 4 bits to get the next half byte
	jmp loop      ; go back to start of loop

end_loop:
	mov si, hex_buffer   ; print the string pointed to
	call print ; by SI
	popa
	ret


main:
	; setup data segment
	mov ax, 0 
	mov ds, ax  ; set data segment to 0
	mov es, ax  ; set extra segment to 0

	; setup stack
	mov ss, ax  ; set stack segment to 0
	mov sp, 0x7C00 ; set stack pointer to 0x7C00

	; print message
    lea si, [msg] ; load address of msg to SI
    call print ; call print function

	; use BIOS to read the disk
	mov ah, 0x02 ; read disk
	mov dl, 0 ; read from floppy disk
	mov ch, 3 ; cylinder 3
	mov dh, 0 ; head 1 (0-based)
	mov cl, 4 ; sector 4 (1-based)
	mov al, 5 ; read 5 sectors

	; Set the memory address to read to
	; es:bx = segment:offset
	; CPU will translate 0xa000:0x1234 to physical address 0xa1234

	mov bx, 0xa000 
	mov es, bx ; indirectly set es to 0xa000
	mov bx, 0x1234 ; set bx to 0x1234

	int 0x13 ; call BIOS interrupt
	jc disk_error ; jump if carry flag is set

	cmp al, 5 ; check if 5 sectors were read
	jne disk_error ; jump to disk_error if not

	lea si, [disk_success_msg] ; load address of disk_success_msg to SI
	call print ; call print function


end:
	hlt ; halt the CPU
	jmp end ; loop forever

msg: db "AL - 1S. System booting...", ENDL, \
    "########################################", ENDL, \
    "#  We thirst for the seven wailings.   #", ENDL, \
    "#  We bear the koan of Jericho.        #", ENDL, \
    "########################################", ENDL, 0 ; message to print



disk_error_msg: db "Disk error", ENDL, 0 ; disk error message

disk_success_msg: db "Disk read successfully", ENDL, 0 ; disk success message

disk_error:
	lea si, [disk_error_msg] ; load address of disk_error_msg to SI
	call print ; call print function
	jmp end ; loop forever

times 510-($-$$) db 0 ; fill the rest of sector with 0s
dw 0xAA55 ; boot signature