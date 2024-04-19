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
	push si ; save source index register to the stack
	push ax ; save registers

.loop:
	lodsb ; load byte from [SI] to AL and increment SI
	or al, al ; check if AL is 0 (end of string)
	jz .done ; if AL is 0, jump to done

	mov ah, 0x0E ; teletype output
	int 0x10 ; call BIOS interrupt

    jmp .loop ; loop

.done:
	pop ax ; restore registers
	pop si ; restore source index register
	ret ; return

; print hex
; Input: AL = value to print
; Output: None
;
print_hex:
	push ax         ; save registers
	mov ah, al      ; move AL to AH
	shr al, 4       ; shift AL 4 bits to the right
	call hex_to_ascii ; call hex_to_ascii
	mov ah, al      ; move AL to AH
	and ah, 0x0F    ; mask the lower 4 bits
	call hex_to_ascii ; call hex_to_ascii

	pop ax          ; restore registers

	mov ecx, hex_buffer  ; Load address of hex_buffer into ecx
	mov [ecx], ah    ; Store the most significant nibble in the buffer
	mov [ecx+1], al  ; Store the least significant nibble in the buffer
	mov esi, hex_buffer ; Point SI to the beginning of hex_buffer
	call print       ; Call the print function to print the hex string
	ret              ; return

; hex to ASCII
; Input: AL = value to convert
; Output: AL = ASCII value
;
hex_to_ascii:
	add al, '0'     ; convert to ASCII
	cmp al, '9'     ; check if AL is greater than '9'
	jbe .done       ; if not, jump to done
	add al, 'A' - '9' - 1 ; convert to ASCII
.done:
	ret             ; return

	

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



end:
	hlt ; halt the CPU
	jmp end ; loop forever

msg: db "AL - 1S. System booting...", ENDL, \
    "########################################", ENDL, \
    "#  We thirst for the seven wailings.   #", ENDL, \
    "#  We bear the koan of Jericho.        #", ENDL, \
    "########################################", ENDL, 0 ; message to print

mov ah, 0x0E ; teletype output
;call print_hex ; call print_hex

times 510-($-$$) db 0 ; fill the rest of sector with 0s
dw 0xAA55 ; boot signature