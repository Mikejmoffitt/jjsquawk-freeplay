	ORG	$0093E2
	jmp	press_start_prompt

; Sets credits based on start button presses
	ORG	$00108E
	jmp	coin_in_if_press_start

; In free play, skip the press-start phase
	ORG	$007C00
	jmp	title_start_mod

; Hide title "FREE                PLAY"
	ORG	$00810E
	jsr	(conditional_print_string).l
	ORG	$0080A2
	jsr	(conditional_print_string).l

	ORG	$0079E8
	jsr	(conditional_print_string).l
	ORG	$007A54
	jsr	(conditional_print_string).l

	ORG	$0084F4
	jsr	(conditional_print_string).l
	ORG	$008560
	jsr	(conditional_print_string).l

; Hide title "Insert Coins"
	ORG	$008072
	jsr	(conditional_print_string).l

	ORG	$0079DC
	jsr	(conditional_print_string).l

	ORG	$008386
	jsr	(conditional_print_string).l

; Disable the nuts dropping from the tree if A+B were held at the start.
	ORG	$0268FC
	jmp	conditional_nuts

NUTS_DISABLE = $7FFA
P1_START_CACHE = $7FFC
P2_START_CACHE = $7FFE

; Macro for checking free play ----------------------------------------------
; Free Play is when the lower 6 bits of (INPUT_DSW + 3).b are clear.
FREEPLAY_MASK = $003F

FREEPLAY macro
	move.l	d1, -(sp)
	move.w	INPUT_DSW + 2, d1
	andi.w	#FREEPLAY_MASK, d1
	beq	.freeplay_is_enabled
	bra	+ ; Jump to anonymous label in user code

.freeplay_is_enabled:
	move.l (sp)+, d1
	ENDM

POST macro
	move.l (sp)+, d1
	ENDM

; ====================================
	ORG	LAST_ORG

; Don't drop nuts if A+B were held at game start
conditional_nuts:
	btst	d1, d3
	btst	d1, d3
	andi.b	#2, d2
	btst	d0, d1
	btst	d0, d1

	tst.w	NUTS_DISABLE(a5)
	beq	.do_nuts
	subq.b	#1, $48(a0)
	rts

.do_nuts:

	subq.b	#1, $48(a0)
	bpl	.ret
	jmp	$026902

.ret:
	rts

press_start_prompt:
	FREEPLAY
	jmp	$009414
/	POST
	tst.w	$42(a5)
	bgt	.show_start
	jmp	$0093E8
.show_start:
	jmp	$009414

conditional_print_string:
	FREEPLAY
	rts
/	POST
	jmp	$00227E

title_start_mod:
	clr.w	NUTS_DISABLE(a5)
	move.w	INPUT_P1, d0
	and.w	INPUT_P2, d0
	andi.w	#$30, d0
	bne	.no_nuts_disable
	move.w	#$0001, NUTS_DISABLE(a5)

.no_nuts_disable:

	jsr	$008250
	FREEPLAY

	tst.w	P2_START_CACHE(a5)
	beq	.not_p2

	jmp	$007CAA  ; Start a 2P game.
.not_p2:
	jmp	$007C18  ; Start a 1P game.
	
/	POST
	tst.b	$E(a5)
	bmi	.game_start
	jmp	$007C0C

.game_start:
	jmp	$007C18  ; Start a 1P game.

coin_in_if_press_start:
	jsr	$00401C

	FREEPLAY
	move.w	INPUT_P1, d0
	not.w	d0
	andi.w	#$0080, d0
	move.w	d0, P1_START_CACHE(a5)

	move.w	INPUT_P2, d0
	not.w	d0
	andi.w	#$0080, d0
	move.w	d0, P2_START_CACHE(a5)

	; Give credits if start is pushed.
	bne	.award_credits
	move.w	P1_START_CACHE(a5), d0
	bne	.award_credits

	; If either player is alive, give credits
	tst.b	$560E(a5)
	bne	.award_credits
	tst.b	$560F(a5)
	bne	.award_credits

	move.w	#0, $42(a5)
	jmp	$001098
	
.award_credits:
	move.w	#9, $42(a5)  ; Toss in 9 credits.
	jmp	$001098
/	POST
	jmp	$001098

LAST_ORG	:=	*
