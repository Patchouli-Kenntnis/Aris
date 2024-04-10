ASM = nasm
SRC_DIR = src
BUILD_DIR = build

${BUILD_DIR}/boot.img: ${BUILD_DIR}/boot.bin 		
	cp ${BUILD_DIR}/boot.bin ${BUILD_DIR}/boot.img 	
	truncate -s 1474560 ${BUILD_DIR}/boot.img 

${BUILD_DIR}/boot.bin: src/boot.asm
	${ASM} src/boot.asm -f bin -o build/boot.bin 