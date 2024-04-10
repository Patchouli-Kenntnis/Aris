org 0x7C00 ; BIOS loads boot sector to 0x7C00
bits 16 ; 16 bit mode

main:
    HLT 
    JMP main ; loop forever

times 510-($-$$) db 0 ; fill the rest of sector with 0s
dw 0xAA55 ; boot signature