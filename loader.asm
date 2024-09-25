; This is the boot sector code

; --------------------------------------------------------------------------------------------------------------------
; Start matter
; --------------------------------------------------------------------------------------------------------------------
[BITS 16]			; Tells the compiler to make this into 16-bit code generation
[ORG 0x7C00]			; Tells the compiler where the code is going to be
				; in memory after it has been loaded. (HEX number)

start:

	mov [bootdrv], dl       	; Before anything else, take note of the 'drive number' where we booted from
					; DL tells us what 'drive number' we booted from, we need this later
					; Store the 'drive number' to the variable 'bootdrv'

	; Setup the stack to be used in function calls.
	; We can't allow interrupts while we set it up

	cli                     ; Disable interrupts (CLear Interrupts bit)
	mov ax, 0x9000          ; Put stack at 9000:0000
	mov ss, ax              ;
	mov sp, 0               ;
	sti                     ; Enable interrupts (SeT Interrupts bit)

; --------------------------------------------------------------------------------------------------------------------
; This is the main loop for the boot loader. It will wait for the "boot" command to be
; entered before the kernel is read from second sector
; see 'routines.asm' for the functions or procedures
; --------------------------------------------------------------------------------------------------------------------
mainloop:
	mov si, prompt           ; Display the "grub>" prompt
	call putstr

	mov di, buffer        	 ; Begin accepting "commands" or input
	call getstr

	cmp di, 0				 ; If not command show prompt
	je mainloop

	mov si, buffer           ; Compare the command issued to the "boot" command
	mov di, cmd_boot
	call strcmp
							 ; If "boot" command is entered, jump to load_kernel

	jc .load_kernel			 ; compare to the original

	jmp mainloop             ; otherwise, show the prompt again

	.load_kernel:

	call read_kernel         ; Load stuff from the bootdrive

	jmp dword KERNEL_SEGMENT:0 	 ;we jump now to the memory location where the kernel was loaded

; --------------------------------------------------------------------------------------------------------------------
; Data section
; Functions and variables used by our bootstrap
; --------------------------------------------------------------------------------------------------------------------
prompt  db "grub>",0
msg     db "Loading kernel...",13,10,0
cmd_boot  db "boot",0
buffer times 64 db 0			; an empty string
bootdrv db 0                    	; The boot drive id
KERNEL_SEGMENT equ 0x1000

; --------------------------------------------------------------------------------------------------------------------
; Read few sectors from the BOOT DRIVE
; --------------------------------------------------------------------------------------------------------------------
read_kernel:
	push ds                 ; save ds
	.reset:
	mov ax, 0               ; Reset Disk first before read
	mov dl, [bootdrv]       ; Drive to reset
	int 13h                 ;
	jc .reset               ; Failed -> Try again

	pop ds

 .read:
	mov ax, KERNEL_SEGMENT	;codes for reading kernel segment
	mov es, ax
	mov bx, 0x0000          ; ES:BX points to the memory location 
	mov ah, 0x02            ; Code below for using INT 0x13
	mov al, 0x01            ; initialization on registers
	mov ch, 0x00            
	mov cl, 0x02            ; 
	mov dh, 0x00            ; 
	mov dl, [bootdrv]       ; DL = drive number (from bootdrv)
	int 0x13                ; 

  retn

; Includes "routines.asm"
	%include "routines.asm"

; --------------------------------------------------------------------------------------------------------------------
; End matter
; --------------------------------------------------------------------------------------------------------------------
	times 510-($-$$) db 0	; Fill the rest of the sector with zero's
	dw 0xAA55		; Add the boot loader signature at the end, size is 2 bytes
