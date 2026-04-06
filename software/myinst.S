   .org 0x0
   .set noat
   .set noreorder
   .set nomacro
   .global _start
_start:
   ori  $1,$0,0x0001   # $1 = 0x1                
   j    zhun1
   ori  $1,$0,0x0002   # $1 = 0x2
   ori  $1,$0,0x1111
   ori  $1,$0,0x1100

zhun1:
   ori  $1,$0,0x0003   # $1 = 0x3               
   jal  zhun2
   div  $zero,$31,$1   # $31 = 0x2c, $1 = 0x3
                       # HI = 0x2, LO = 0xe 
   ori  $1,$0,0x0005   # r1 = 0x5
   ori  $1,$0,0x0006   # r1 = 0x6
   j    zhun3
   nop


zhun2:               
   jalr $2,$31           
   or   $1,$2,$0        # $1 = 0x48
   ori  $1,$0,0x0009    # $1 = 0x9
   ori  $1,$0,0x000a    # $1 = 0xa
   j zhun4
   nop

zhun3:
   ori  $1,$0,0x0007    # $1 = 0x7                
   jr   $2           
   ori  $1,$0,0x0008    # $1 = 0x8
   ori  $1,$0,0x1111
   ori  $1,$0,0x1100

zhun4:
   nop


   ori  $3,$0,0x8000
   sll  $3,16               # $3 = 0x80000000
   ori  $1,$0,0x0001        # $1 = 0x1                
   b    s1
   ori  $1,$0,0x0002        # $1 = 0x2
1:
   ori  $1,$0,0x1111
   ori  $1,$0,0x1100


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


s3:
   ori  $1,$0,0x0005      # $1 = 0x5            
   BGEZ $1,2b           
   ori  $1,$0,0x0006      # $1 = 0x6
   ori  $1,$0,0x1111
   ori  $1,$0,0x1100


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


s5:
   ori  $1,$0,0x0010      # $1 = 0x10            
   blez $1,2b           
   ori  $1,$0,0x0011      # $1 = 0x11
   ori  $1,$0,0x0012      # $1 = 0x12
   ori  $1,$0,0x0013      # $1 = 0x13
   bltzal $3,s6
   or   $1,$0,$31         # $1 = 0x14c
   ori  $1,$0,0x1100


s6:
   ori $1,$0,0x0014       # $1 = 0x14
   nop



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
   lw   $1, 0x4($0)      # $1 = 0xaabb88bb

   ori $1,$0,0x1234    # $1 = 0x00001234
   sw  $1,0x0($0)      # [0x0] = 0x00001234

   ori $1,$0,0x5678    # $1 = 0x00005678
   sc  $1,0x0($0)      # $1 = 0x0
   lw  $1,0x0($0)      # $1 = 0x00001234
   nop
   #ll,sc指令验证
   ori $1,$0,0x0       # $1 = 0x0
   ll  $1,0x0($0)      # $1 = 0x00001234
   nop
   addi $1,$1,0x1      # $1 = 0x00001235
   sc  $1,0x0($0)      # $1 = 0x1
   lw  $1,0x0($0)      # $1 = 0x00001235     

   ori $1,$0,0x1234    # $1 = 0x00001234
   sw  $1,0x0($0)      # [0x0] = 0x00001234

   ori $2,$0,0x1234    # $2 = 0x00001234
   ori $1,$0,0x0       # $1 = 0x0
   lw  $1,0x0($0)      # $1 = 0x00001234
   beq $1,$2,Label1    
   nop

   ori $1,$0,0x4567    
   nop

Label1:
   ori $1,$0,0x89ab    # $1 = 0x000089ab    
   nop            
    
   ori $1,$0,0xf  #$1 = 0xf
   mtc0 $1,$11,0x0  #将0xf写入CP0中的Compare寄存器

   lui $1,0x1000 
   ori $1,$1,0x401 #$1 = 0×10000401
   mtc0 $1,$12,0x0     #将0×10000401写入CPO中的Status寄存器
   mfc0 $2,$12,0x0  #读status寄存器，保存到寄存器$2，$2 =0x10000401


_loop:
   j _loop
   nop