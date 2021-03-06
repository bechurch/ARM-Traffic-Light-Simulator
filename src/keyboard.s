
	.include "keyboard.a"
	.include "interrupt.a"

	.equ	rEXTINT,		0x1d20050
	.equ	rEXTINTPND,		0x1d20054
	.equ	rPCONG,			0x1d20040
	.equ	rPDATG,			0x1d20044
	.equ	rPUPG,			0x1d20048

	.equ	keyboard_base,	0x06000000

	.text
	.global	keyboard_init
	.global	keyboard_checkBlackKeyAndClear
	.global	keyboard_checkBlueKeyAndClear
	.global	keyboard_close
	.global keyboard_clearAll
	

keyboard_clearAll:
	stmfd	sp!,{r0-r1,lr}

	@clear EXTINTPND reg
	ldr	r0,=rEXTINTPND
	ldr	r1,=0xf
	str	r1,[r0]
	
	ldmfd	sp!,{r0-r1,pc}

keyboard_init:
	stmfd	sp!,{r0-r1,lr}

	@PORT G
	ldr	r0,=rPCONG
	ldr	r1,=0xffff
	str	r1,[r0]

	ldr	r0,=rPUPG
	ldr	r1,=0x00			@pull up enable
	str	r1,[r0]

	ldr	r0,=rEXTINT
	ldr	r1,[r0]
	orr	r1,r1,#0x20			@EINT1 falling edge mode
	str	r1,[r0]

	ldr	r0,=blue_key
	ldr	r1,=0
	str	r1,[r0]

	ldr	r0,=black_key
	str	r1,[r0]

	@clear pending bit
	ldr	r0,=(BIT_EINT1|BIT_EINT4567)
	bl	interrupt_clear_pending
	
	@clear EXTINTPND reg
	ldr	r0,=rEXTINTPND
	ldr	r1,=0xf
	str	r1,[r0]

	@set black keys interrupt handler
	ldr	r0,=BIT_EINT4567
	ldr	r1,=keyboard_black_int
	bl	interrupt_setvector

	@set blue keys interrupt handler
	ldr	r0,=BIT_EINT1
	ldr	r1,=keyboard_blue_int
	bl	interrupt_setvector

	@enable interrupts in controller
	ldr	r0,=(BIT_EINT1|BIT_EINT4567)
	bl	interrupt_enable

	ldmfd	sp!,{r0-r1,pc}


keyboard_close:
	stmfd	sp!,{r0-r1,lr}

	@disable interrupts in controller
	ldr	r0,=(BIT_EINT1|BIT_EINT4567)
	bl	interrupt_disable

	@set black keys interrupt handler to null
	ldr	r0,=BIT_EINT1
	ldr	r1,=0x00
	bl	interrupt_setvector

	@set blue keys interrupt handler to null
	ldr	r0,=BIT_EINT4567
	ldr	r1,=0x00
	bl	interrupt_setvector
	
	ldmfd	sp!,{r0-r1,pc}


keyboard_black_int:
	stmfd	sp!,{r0-r2,lr}

	@clear EXTINTPND reg
    ldr		r0,=rEXTINTPND
    ldr		r1,[r0]
    ldr		r2,=0xf;				
	str		r2,[r0]
	
	@clear pending bit
	ldr		r0,=BIT_EINT4567
	bl		interrupt_clear_pending

	ldr		r0,=black_key
	ldr		r2,=LEFT_BLACK_BUTTON
	cmp		r1,#0x04
	streq	r2,[r0]
	ldr		r2,=RIGHT_BLACK_BUTTON
	cmp		r1,#0x08
	streq	r2,[r0]
	
	ldmfd	sp!,{r0-r2,lr}
	subs	pc,lr,#4


keyboard_blue_int:
	stmfd	sp!,{r0-r4,lr}

	@clear pending bit
	ldr		r0,=BIT_EINT1
	bl		interrupt_clear_pending
	
	mov		r2,#1
	mov		r1,#2
	ldr		r0,=(keyboard_base+0xfd)
kbi05:
	ldrb	r3,[r0]
	and		r3,r3,#0x0f
	cmp		r3,#0x0f
	beq		kbi10
		
	mov		r3,r3,lsl#28
	mov		r4,#4
kbi15:
	movs	r3,r3,lsl#1
	bcc		kbi99
	mov		r2,r2,lsl#1
	subs	r4,r4,#1
	bne		kbi15	
kbi10:
	mov		r2,r2,lsl#4
	sub		r0,r0,r1
	mov		r1,r1,lsl#1
	cmp		r1,#0x10
	ble		kbi05
	b		kbi98
	;;mov		r2,#0
kbi99:
	ldr		r0,=blue_key
	str		r2,[r0]
	
kbi98:
	ldmfd	sp!,{r0-r4,lr}
	subs	pc,lr,#4


keyboard_checkBlackKeyAndClear:
	stmfd	sp!,{r1-r2,lr}
	ldr		r1,=black_key
	ldr		r0,[r1]
	ldr		r2,=0
	str		r2,[r1]
	ldmfd	sp!,{r1-r2,pc}
	
keyboard_checkBlueKeyAndClear:
	stmfd	sp!,{r1-r2,lr}
	ldr		r1,=blue_key
	ldr		r0,[r1]
	ldr		r2,=0
	str		r2,[r1]
	ldmfd	sp!,{r1-r2,pc}

	.data
	.align
blue_key:	.word	0
black_key:	.word	0
	.end
	
