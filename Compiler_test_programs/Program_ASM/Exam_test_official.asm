;***************************************************************
; MAIN CODE
;***************************************************************
main:
	addi r1, r0, 5
	xor r2, r2, r2

ciclo:
	lw r3, 6(r2)
	addi r3, r3, 10
	sw 100(r2), r3
	subi r1, r1, 1
	addi r2, r2, 4
	nop
	nop
	nop
	bnez r1, ciclo

	addi r4, r0, 65535 
	ori r5, r4, 100000
	sge r1,r2,r10
	nop
	nop
	nop

	call sub1
	addi r31,r2,#10
	nop
	nop
	nop
	ret
	mult r5,r2,r3
end:
	j end
	or r5, r3, r4



;***************************************************************
; FUNCTIONS
;***************************************************************

;----------------------------
sub1:
	add r9,r20,r10
	addi r1,r2,#-5
	and r8,r3,r10
	sleu r13,r2,r9
	xor r20, r20, r25 ; toggle lsb of r20. 
	nop
	nop
	nop
	call sub2
	ret
;----------------------------
sub2:
	call sub3
	ret
;----------------------------
sub3:
	call sub4
	ret
;----------------------------
sub4:
	call sub5
	sleui r22,r30,#30 ;f3d6001e
	lhu r2,40+4(r3)
	jal label4
	add r9,r20,r10
label4:
	sgti r4,r1,#15
	nop
	nop
	nop
	ret
;----------------------------
sub5
	call sub6
	ret
;----------------------------
sub6:
	add r9,r20,r10
	nop
	nop
	nop
	call sub7
	ret
;----------------------------
sub7:
	addi r1,r2,#-5
	xori r6,r12,#1
	subi r7,r9,#-30
	srai r25,r26,#10
	sltu r17,r13,r14
	nop
	nop
	nop
	ret
;----------------------------
