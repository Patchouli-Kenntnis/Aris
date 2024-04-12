org 0x7C00 ; BIOS loads boot sector to 0x7C00
bits 16 ; 16 bit mode
%define ENDL 0x0D, 0x0A ; new line characters

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

times 510-($-$$) db 0 ; fill the rest of sector with 0s
dw 0xAA55 ; boot signature