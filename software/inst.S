	.org 0x0
.global _start
   .set noat
_start:
   ori $1,$0,0x1100        # $1 = $0 | 0x1100 = 0x1100
   ori $2,$0,0x0020        # $2 = $0 | 0x0020 = 0x0020
   ori $3,$0,0xff00        # $3 = $0 | 0xff00 = 0xff00
   ori $4,$0,0xffff        # $4 = $0 | 0xffff = 0xffff

   .org 0x0
   .set noat
   .global _start
_start:
   lui   $2,0x0404
   ori   $2,$2,0x0404
   ori   $7,$0,0x7
   ori   $5,$0,0x5
   ori   $8,$0,0x8
   sync
   sll   $2,$2,8    # $2 = 0x40404040 sll 8  = 0x04040400
   sllv  $2,$2,$7   # $2 = 0x04040400 sll 7  = 0x02020000
   srl   $2,$2,8    # $2 = 0x02020000 srl 8  = 0x00020200
   srlv  $2,$2,$5   # $2 = 0x00020200 srl 5  = 0x00001010
   nop
   sll   $2,$2,19   # $2 = 0x00001010 sll 19 = 0x80800000
   ssnop
   sra   $2,$2,16   # $2 = 0x80800000 sra 16 = 0xffff8080
   srav  $2,$2,$8   # $2 = 0xffff8080 sra 8  = 0xffffff80 

	.org 0x0
.global _start
   .set noat
_start:
   lui  $1,0x0101
   ori  $1,$1,0x0101
   ori  $2,$1,0x1100        # $2 = $1 | 0x1100 = 0x01011101
   or   $1,$1,$2            # $1 = $1 | $2 = 0x01011101
   andi $3,$1,0x00fe        # $3 = $1 & 0x00fe = 0x00000000
   and  $1,$3,$1            # $1 = $3 & $1 = 0x00000000
   xori $4,$1,0xff00        # $4 = $1 ^ 0xff00 = 0x0000ff00
   xor  $1,$4,$1            # $1 = $4 ^ $1 = 0x0000ff00
   nor  $1,$4,$1            # $1 = $4 ~^ $1 = 0xffff00ff   nor is "not or"


   .org 0x0
   .set noat
   .global _start
_start:
   lui $1,0x0000          # $1 = 0x00000000
   lui $2,0xffff          # $2 = 0xffff0000
   lui $3,0x0505          # $3 = 0x05050000
   lui $4,0x0000          # $4 = 0x00000000 

   movz $4,$2,$1          # $4 = 0xffff0000
   movn $4,$3,$1          # $4 = 0xffff0000
   movn $4,$3,$2          # $4 = 0x05050000
   movz $4,$2,$3          # $4 = 0x05050000

   mthi $0                # hi = 0x00000000
   mthi $2                # hi = 0xffff0000
   mthi $3                # hi = 0x05050000
   mfhi $4                # $4 = 0x05050000

   mtlo $3                # li = 0x05050000
   mtlo $2                # li = 0xffff0000
   mtlo $1                # li = 0x00000000
   mflo $4                # $4 = 0x00000000        


   .org 0x0
   .set noat
   .global _start
_start:

   ######### add\addi\addiu\addu\sub\subu ##########

   ori  $1,$0,0x8000           # $1 = 0x8000
   sll  $1,$1,16               # $1 = 0x80000000
   ori  $1,$1,0x0010           # $1 = 0x80000010

   ori  $2,$0,0x8000           # $2 = 0x8000
   sll  $2,$2,16               # $2 = 0x80000000
   ori  $2,$2,0x0001           # $2 = 0x80000001

   ori  $3,$0,0x0000           # $3 = 0x00000000
   addu $3,$2,$1               # $3 = 0x00000011
   ori  $3,$0,0x0000           # $3 = 0x00000000
   add  $3,$2,$1               # overflow,$3 keep 0x00000000

   sub   $3,$1,$3              # $3 = 0x80000010         
   subu  $3,$3,$2              # $3 = 0xF

   addi $3,$3,2                # $3 = 0x11
   ori  $3,$0,0x0000           # $3 = 0x00000000
   addiu $3,$3,0x8000          # $3 = 0xffff8000

   #########     slt\sltu\slti\sltiu     ##########

   or   $1,$0,0xffff           # $1 = 0xffff
   sll  $1,$1,16               # $1 = 0xffff0000
   slt  $2,$1,$0               # $2 = 1
   sltu $2,$1,$0               # $2 = 0
   slti $2,$1,0x8000           # $2 = 1
   sltiu $2,$1,0x8000          # $2 = 1

   #########          clo\clz          ##########

   lui $1,0x0000          # $1 = 0x00000000
   clo $2,$1              # $2 = 0x00000000
   clz $2,$1              # $2 = 0x00000020

   lui $1,0xffff          # $1 = 0xffff0000
   ori $1,$1,0xffff       # $1 = 0xffffffff
   clz $2,$1              # $2 = 0x00000000
   clo $2,$1              # $2 = 0x00000020

   lui $1,0xa100          # $1 = 0xa1000000
   clz $2,$1              # $2 = 0x00000000
   clo $2,$1              # $2 = 0x00000001

   lui $1,0x1100          # $1 = 0x11000000
   clz $2,$1              # $2 = 0x00000003
   clo $2,$1              # $2 = 0x00000000

   ori  $1,$0,0xffff                  
   sll  $1,$1,16
   ori  $1,$1,0xfffb           # $1 = -5
   ori  $2,$0,6                # $2 = 6
   mul  $3,$1,$2               # $3 = -30 = 0xffffffe2
  
   mult $1,$2                  # hi = 0xffffffff
                               # lo = 0xffffffe2

   multu $1,$2                 # hi = 0x5
                               # lo = 0xffffffe2
   nop
   nop

   .org 0x0
   .set noat
   .global _start
_start:
   ori  $1,$0,0xffff                  
   sll  $1,$1,16
   ori  $1,$1,0xfffb           # $1 = -5
   ori  $2,$0,6                # $2 = 6

   mult $1,$2                  # hi = 0xffffffff
                               # lo = 0xffffffe2

   madd $1,$2                  # hi = 0xffffffff
                               # lo = 0xffffffc4

   maddu $1,$2                 # hi = 0x5
                               # lo = 0xffffffa6

   msub $1,$2                  # hi = 0x5
                               # lo = 0xffffffc4   

   msubu $1,$2                 # hi = 0xffffffff
                               # lo = 0xffffffe2   

   .org 0x0
   .set noat
   .set noreorder
   .set nomacro
   .global _start
_start:
   ori  $1,$0,0x0001   # $1 = 0x1                
   j    0x20
   ori  $1,$0,0x0002   # $1 = 0x2
   ori  $1,$0,0x1111
   ori  $1,$0,0x1100

   .org 0x20
   ori  $1,$0,0x0003   # $1 = 0x3               
   jal  0x40
   div  $zero,$31,$1   # $31 = 0x2c, $1 = 0x3
                       # HI = 0x2, LO = 0xe 
   ori  $1,$0,0x0005   # r1 = 0x5
   ori  $1,$0,0x0006   # r1 = 0x6
   j    0x60
   nop

   .org 0x40
               
   jalr $2,$31           
   or   $1,$2,$0        # $1 = 0x48
   ori  $1,$0,0x0009    # $1 = 0x9
   ori  $1,$0,0x000a    # $1 = 0xa
   j 0x80
   nop

   .org 0x60
   ori  $1,$0,0x0007    # $1 = 0x7                
   jr   $2           
   ori  $1,$0,0x0008    # $1 = 0x8
   ori  $1,$0,0x1111
   ori  $1,$0,0x1100

   .org 0x80
   nop
    
_loop:
   j _loop
   nop
   .org 0x0
   .set noat
   .set noreorder
   .set nomacro
   .global _start
_start:
   ori  $3,$0,0x8000
   sll  $3,16               # $3 = 0x80000000
   ori  $1,$0,0x0001        # $1 = 0x1                
   b    s1
   ori  $1,$0,0x0002        # $1 = 0x2
1:
   ori  $1,$0,0x1111
   ori  $1,$0,0x1100

   .org 0x20
s1:
   ori  $1,$0,0x0003        # $1 = 0x3          
   bal  s2
   div  $zero,$31,$1        # $31 = 0x2c, $1 =0x3
                            # HI = 0x2, LO = 0xe 
   ori  $1,$0,0x1100
   ori  $1,$0,0x1111
   bne  $1,$0,s3
   nop
   ori  $1,$0,0x1100
   ori  $1,$0,0x1111

   .org 0x50   
s2:
   ori  $1,$0,0x0004      # $1 = 0x4
   beq  $3,$3,s3           
   or   $1,$31,$0         # $1 = 0x2c
   ori  $1,$0,0x1111
   ori  $1,$0,0x1100
2:
   ori  $1,$0,0x0007      # $1 = 0x7
   ori  $1,$0,0x0008      # $1 = 0x8
   bgtz $1,s4
   ori  $1,$0,0x0009      # $1 = 0x9
   ori  $1,$0,0x1111
   ori  $1,$0,0x1100

   .org 0x80
s3:
   ori  $1,$0,0x0005      # $1 = 0x5            
   BGEZ $1,2b           
   ori  $1,$0,0x0006      # $1 = 0x6
   ori  $1,$0,0x1111
   ori  $1,$0,0x1100

   .org 0x100
s4:
   ori  $1,$0,0x000a      # $1 = 0xa              
   BGEZAL $3,s3
   or   $1,$0,$31         # $1 = 0x10c          
   ori  $1,$0,0x000b      # $1 = 0xb
   ori  $1,$0,0x000c      # $1 = 0xc
   ori  $1,$0,0x000d      # $1 = 0xd
   ori  $1,$0,0x000e      # $1 = 0xe
   bltz $3,s5
   ori  $1,$0,0x000f      # $1 = 0xf
   ori  $1,$0,0x1100


   .org 0x130
s5:
   ori  $1,$0,0x0010      # $1 = 0x10            
   blez $1,2b           
   ori  $1,$0,0x0011      # $1 = 0x11
   ori  $1,$0,0x0012      # $1 = 0x12
   ori  $1,$0,0x0013      # $1 = 0x13
   bltzal $3,s6
   or   $1,$0,$31         # $1 = 0x14c
   ori  $1,$0,0x1100


   .org 0x160
s6:
   ori $1,$0,0x0014       # $1 = 0x14
   nop
   
   
    
_loop:
   j _loop
   nop
   .org 0x0
   .set noat
   .set noreorder
   .set nomacro
   .global _start
_start:
   ori  $3,$0,0xeeff
   sb   $3,0x3($0)       # [0x3] = 0xff
   srl  $3,$3,8
   sb   $3,0x2($0)       # [0x2] = 0xee
   ori  $3,$0,0xccdd
   sb   $3,0x1($0)       # [0x1] = 0xdd
   srl  $3,$3,8
   sb   $3,0x0($0)       # [0x0] = 0xcc
   lb   $1,0x3($0)       # $1 = 0xffffffff
   lbu  $1,0x2($0)       # $1 = 0x000000ee
   nop

   ori  $3,$0,0xaabb
   sh   $3,0x4($0)       # [0x4] = 0xaa, [0x5] = 0xbb
   lhu  $1,0x4($0)       # $1 = 0x0000aabb
   lh   $1,0x4($0)       # $1 = 0xffffaabb
 
   ori  $3,$0,0x8899
   sh   $3,0x6($0)       # [0x6] = 0x88, [0x7] = 0x99
   lh   $1,0x6($0)       # $1 = 0xffff8899
   lhu  $1,0x6($0)       # $1 = 0x00008899

   ori  $3,$0,0x4455
   sll  $3,$3,0x10
   ori  $3,$3,0x6677     
   sw   $3,0x8($0)       # [0x8] = 0x44, [0x9]= 0x55, [0xa]= 0x66, [0xb] = 0x77
   lw   $1,0x8($0)       # $1 = 0x44556677

   lwl  $1, 0x5($0)      # $1 = 0xbb889977
   lwr  $1, 0x8($0)      # $1 = 0xbb889944

   nop
   swr  $1, 0x2($0)      # [0x0] = 0x88, [0x1] = 0x99, [0x2]= 0x44, [0x3] = 0xff
   swl  $1, 0x7($0)      # [0x4] = 0xaa, [0x5] = 0xbb, [0x6] = 0x88, [0x7] = 0x44

   lw   $1, 0x0($0)      # $1 = 0x889944ff
   lw   $1, 0x4($0)      # $1 = 0xaabb8844
    
_loop:
   j _loop
   nop

   .org 0x0
   .set noat
   .set noreorder
   .set nomacro
   .global _start
_start:
   ori $1,$0,0x1234    # $1 = 0x00001234
   sw  $1,0x0($0)      # [0x0] = 0x00001234

   ori $1,$0,0x5678    # $1 = 0x00005678
   sc  $1,0x0($0)      # $1 = 0x0
   lw  $1,0x0($0)      # $1 = 0x00001234
   nop

   ori $1,$0,0x0       # $1 = 0x0
   ll  $1,0x0($0)      # $1 = 0x00001234
   nop
   addi $1,$1,0x1      # $1 = 0x00001235
   sc  $1,0x0($0)      # $1 = 0x1
   lw  $1,0x0($0)      # $1 = 0x00001235               
    
_loop:
   j _loop
   nop

   .org 0x0
   .set noat
   .set noreorder
   .set nomacro
   .global _start
_start:
   ori $1,$0,0x1234    # $1 = 0x00001234
   sw  $1,0x0($0)      # [0x0] = 0x00001234

   ori $2,$0,0x1234    # $2 = 0x00001234
   ori $1,$0,0x0       # $1 = 0x0
   lw  $1,0x0($0)      # $1 = 0x00001234
   beq $1,$2,Label     
   nop

   ori $1,$0,0x4567    
   nop

Label:
   ori $1,$0,0x89ab    # $1 = 0x000089ab    
   nop            
    
_loop:
   j _loop
   nop

   .org 0x0
   .set noat
   .set noreorder
   .set nomacro
   .global _start
_start:
   ori $1,$0,0xf
   mtc0 $1,$11,0x0  #Ð´compare¼Ä´æÆ÷£¬¿ªÊ¼¼ÆÊ±
   lui $1,0x1000
   ori $1,$1,0x401
   mtc0 $1,$12,0x0  #½«0x401Ð´Èçstatus¼Ä´æÆ÷
   mfc0 $2,$12,0x0  #¶Ástatus¼Ä´æÆ÷£¬$2=0x401

_loop:
   j _loop
   nop
   
   
   .org 0x0
   .set noat
   .set noreorder
   .set nomacro
   .global _start
_start:
   ori $1,$0,0x100     # $1 = 0x100
   jr $1
   nop

   .org 0x40
   ori $1,$0,0x8000    # $1 = 0x00008000
   ori $1,$0,0x9000    # $1 = 0x00009000
   mfc0 $1,$14,0x0     # $1 = 0x0000010c
   addi $1,$1,0x4      # $1 = 0x00000110
   mtc0 $1,$14,0x0
   eret
   nop

   .org 0x100
   ori $1,$0,0x1000    # $1 = 0x1000
   sw  $1, 0x0100($0)  # [0x100] = 0x00001000
   mthi $1             # HI = 0x00001000
   syscall
   lw  $1, 0x0100($0)  # $1 = 0x00001000
   mfhi $2             # $2 = 0x00001000             
_loop:
   j _loop
   nop
   
   

   .org 0x0
   .set noat
   .set noreorder
   .set nomacro
   .global _start
_start:
   ori $1,$0,0x100     # $1 = 0x100
   jr $1
   nop

   .org 0x40
   ori $1,$0,0xf0f0    # $1 = 0x0000f0f0
   ori $1,$0,0xffff    # $1 = 0x0000ffff
   ori $1,$0,0x0f0f    # $1 = 0x00000f0f
   mfc0 $4,$14,0x0     
   addi $4,$4,0x4      
   mtc0 $4,$14,0x0
   eret
   nop

   .org 0x100
   ori $1,$0,0x1000    # $1 = 0x00001000
   ori $2,$0,0x1000    # $2 = 0x00001000
   teq $1,$2           # trap happen
   ori $1,$0,0x2000    # $1 = 0x00002000
   tne $1,$2           # trap happen
   ori $1,$0,0x3000    # $1 = 0x00003000
   teqi $1,0x3000      # trap happen
   ori $1,$0,0x4000    # $1 = 0x00004000
   tnei $1,0x2000      # trap happen
   ori $1,$0,0x5000    # $1 = 0x00005000
   tge $1,$2           # trap happen
   ori $1,$0,0x6000    # $1 = 0x00006000
   tgei $1,0x4000      # trap happen
   ori $1,$0,0x7000    # $1 = 0x00007000
   tgeiu $1,0x7000     # trap happen
   ori $1,$0,0x8000    # $1 = 0x00008000
   tgeu $1,$2          # trap happen
   ori $1,$0,0x9000    # $1 = 0x00009000
   tlt $1,$2           # not trap
   ori $1,$0,0xa000    # $1 = 0x0000a000
   tlti $1,0x9000      # not trap
   ori $1,$0,0xb000    # $1 = 0x0000b000
   tltiu $1,0xb000     # trap happen ecause $1=0xb000 < 0xffffb000
   ori $1,$0,0xc000    # $1 = 0x0000c000
   tltu $2,$1          # trap happen
   ori $1,$0,0xd000    # $1 = 0x0000d000
_loop:
   j _loop
   nop
   
   
   .org 0x0
   .set noat
   .set noreorder
   .set nomacro
   .global _start
_start:
   ori $1,$0,0x100     # $1 = 0x100
   jr $1
   nop

   .org 0x20
   addi $2,$2,0x1
   mfc0 $1,$11,0x0
   addi $1,$1,100
   mtc0 $1,$11,0x0
   eret
   nop

   .org 0x100
   ori $2,$0,0x0
   ori $1,$0,100
   mtc0 $1,$11,0x0  
   lui $1,0x1000
   ori $1,$1,0x401
   mtc0 $1,$12,0x0
  

_loop:
   j _loop
   nop
   