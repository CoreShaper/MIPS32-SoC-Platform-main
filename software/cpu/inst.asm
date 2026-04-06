
inst.om:     file format elf32-tradbigmips

Disassembly of section .text:

00000000 <_start>:
   0:	34010100 	li	at,0x100
   4:	3c022000 	lui	v0,0x2000
   8:	00200008 	jr	at
   c:	00000000 	nop
	...
  20:	40016800 	mfc0	at,c0_cause
  24:	30240800 	andi	a0,at,0x800
  28:	14800049 	bnez	a0,150 <_int2>
  2c:	00000000 	nop
  30:	42000018 	eret
	...
 100:	34050000 	li	a1,0x0
 104:	34060000 	li	a2,0x0
 108:	34070000 	li	a3,0x0
 10c:	34080000 	li	t0,0x0
 110:	34090000 	li	t1,0x0
 114:	340a0000 	li	t2,0x0
 118:	34030003 	li	v1,0x3
 11c:	ac430004 	sw	v1,4(v0)
 120:	3c011000 	lui	at,0x1000
 124:	34210801 	ori	at,at,0x801
 128:	40816000 	mtc0	at,c0_status
 12c:	34030098 	li	v1,0x98
 130:	ac430000 	sw	v1,0(v0)
 134:	340300f0 	li	v1,0xf0
 138:	ac430000 	sw	v1,0(v0)
 13c:	3403000f 	li	v1,0xf
 140:	ac430000 	sw	v1,0(v0)

00000144 <_loop>:
 144:	00000000 	nop
 148:	08000051 	j	144 <_loop>
 14c:	00000000 	nop

00000150 <_int2>:
 150:	8c430000 	lw	v1,0(v0)
 154:	ac430000 	sw	v1,0(v0)
 158:	42000018 	eret
	...
Disassembly of section .reginfo:

00000000 <.reginfo>:
   0:	000007fe 	0x7fe
	...
