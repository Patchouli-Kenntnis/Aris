org 0x7C00 ; BIOS loads boot sector to 0x7C00
bits 16 ; 16 bit mode
%define ENDL 0x0D, 0x0A ; new line characters
hex_buffer: db '0x0000', 0 ; buffer to store hex string


start:
	jmp main ; jump to main


; load DH sectors to ES:BX from drive DL
; Output: None
disk_load :
	push dx ; Store DX on stack so later we can recall
	; how many sectors were request to be read ,
	; even if it is altered in the meantime
	mov ah , 0x02 ; BIOS read sector function
	mov al , dh ; Read DH sectors
	mov ch , 0x00 ; Select cylinder 0
	mov dh , 0x00 ; Select head 0
	mov cl , 0x02 ; Start reading from second sector ( i.e.
	; after the boot sector )
	int 0x13 ; BIOS interrupt

	; check for error
	jc disk_error ; Jump if error ( i.e. carry flag set )
	pop dx ; Restore DX from the stack
	cmp dh , al ; if AL ( sectors read ) != DH ( sectors expected )
	jne disk_error ; display error message
	
	; if no error, print success message
	lea si, [disk_success_msg] ; load address of disk_success_msg to SI
	call print ; call print function

	ret


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

	; load sectors
	mov [BOOT_DRIVE], dl ; save boot drive

	mov bp, 0x8000 ; base pointer to 0x8000
	mov sp, bp ; stack pointer to 0x8000

	mov bx, 0x9000 ; buffer address
	mov dh, 5 ; read 5 sectors
	mov dl, [BOOT_DRIVE] ; boot drive
	call disk_load ; call disk_load function

	mov dx, [0x9000] ; Print out the first loaded word, which
	call print_hex ; we expect to be 0x1989 , stored
	; at address 0x9000


	mov dx , [0x9000 + 720] ; Also, print the first word from the second
	call print_hex ; 2nd loaded sector : should be 0x0604


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

; Global variables
BOOT_DRIVE : db 0 ; boot drive

times 510-($-$$) db 0 ; fill the rest of sector with 0s
dw 0xAA55 ; boot signature

; We know that BIOS will load only the first 512 - byte sector from the disk ,
; so if we purposely add a few more sectors to our code by repeating some
; familiar numbers , we can prove to ourselfs that we actually loaded those
; additional two sectors from the disk we booted from.
times 256 dw 0x1989
times 256 dw 0x0604