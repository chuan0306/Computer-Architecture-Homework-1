.data
    t1_u: .word 0x0f000000        # upper bits of test data 1, test_data1[0~31]
    t1_l: .word 0x00000000        # lower bits of test data 2, test_data2[32~63]
    t2_u: .word 0x00000000
    t2_l: .word 0x00000000
    t3_u: .word 0x01234567
    t3_l: .word 0x89abcdef
.text
main:
    # initial setting
    la    t0, t1_u                # load address of upper bits of test data 1 into s0 
    la    t1, t2_u
    la    t2, t3_u
    addi  sp, sp, -12
    sw    t0, 0(sp)
    sw    t1, 4(sp)
    sw    t2, 8(sp)
    add   s0, zero, t0            # s0 = & test_data_upper
    add   s1, zero, zero        # int i (used for test data loop control)            
    addi  s2, zero, 3            # upper bound of i (used for loop control)
    addi  s3, zero, 4
    addi  s4, zero, -1            # be used to do not operation
    
main_for_loop:
    # call finding_string procedure
    #mv   a0, s0        # a0 = & test_data_1_upper
    jal   ra, fs
    li    a7, 1
    ecall
    li    a0, 0
    li    a7, 11
    ecall
       
    addi  s1, s1, 1
    addi  s0, s0, 8
    blt   s1, s2, -12
    li    a7, 11
    ecall
    j     Exit
    

fs:
    addi  sp, sp, -16
    sw    ra, 0(sp)
    sw    s1, 4(sp)
    sw    s2, 8(sp)
    sw    s3, 12(sp)
    #sw    s4, 16(sp)
    addi  s1, s0, 4    # s1 = & test_date_lower
    lw    a1, 0(s0)    # a1 = value of test_data upper
    lw    a2, 0(s1)    # a2 = value of test_date lower, test_data = [a1, a2]
    #li    s2, 0        # s2 = clz = 0
    li    s2, 0        # s2 = pos = 0   
   
x_equal_0_check:
    bne   a1, zero, x_not_equal_0
    bne   a2, zero, x_not_equal_0 
    
x_eqaul_0:
    addi  a0, zero, -1
    j     fs_end
    
x_not_equal_0:
    jal   ra, CLZ
    # x = x << clz
    li    t0, 32
    sub   t0, t0, a0    
    srl   a4, a2, t0 
    sll   a3, a1, a0
    or    a3, a3, a4    # a1 = a1 << clz 
    sll   a4, a2, a0    # a2 = a2 << clz, x([a3, a4]) = x([a1, a2]) << clz
    # pos = pos + clz
    add   s2, s2, a0
    # x = -x, [a3, a4] = - [a1, a2]
    xor   a1, a3, s4
    xor   a2, a4, s4
    jal   ra, CLZ
    # check: clz > n
    bge   a0, s3, 32
    ## < case
    # x = x << clz
    sub   t0, t0, a0    
    srl   a2, a4, t0 
    sll   a1, a3, a0
    or    a1, a1, a2    # a1 = a3 << clz 
    sll   a2, a4, a0    # a2 = a4 << clz, x([a1, a2]) = x([a3, a4]) << clz
    # pos = pos + clz
    add   s2, s2, a0
    j     x_equal_0_check
    ## >= base
    mv    a0, s2
    j     fs_end
    
fs_end:
    lw    ra, 0(sp)
    lw    s1, 4(sp)
    lw    s2, 8(sp)
    lw    s3, 12(sp)
    addi  sp, sp, 16
    jalr  ra
CLZ:
    addi  sp, sp, -4
    sw    ra, 0(sp)
    mv    t0, a1
    mv    t1, a2
    li    t4, 0x55555555
    li    t5, 0x33333333
    li    t6, 0x0f0f0f0f
    # x |= (x>>1);
    srli  t3, t1, 1    # shift lower bits of test data right with 1 bit
    slli  t2, t0, 31   # shift upper bits of test data left with 31 bits 
    or    t3, t2, t3   # combine to get new lower bits of test data
    srli  t2, t0, 1    # shift upper bound of test data right with 1 bit
    or    t0, t0, t2   # [0~31]x | [0~31](x >> 1)
    or    t1, t1, t3   # [32~63]x | [32~63](x >> 1)
    # x |= (x>>2);
    srli  t3, t1, 2  
    slli  t2, t0, 30  
    or    t3, t2, t3  
    srli  t2, t0, 2   
    or    t0, t0, t2  
    or    t1, t1, t3 
    # x |= (x>>4);
    srli  t3, t1, 4  
    slli  t2, t0, 28  
    or    t3, t2, t3  
    srli  t2, t0, 4   
    or    t0, t0, t2  
    or    t1, t1, t3  
    # x |= (x>>8);
    srli  t3, t1, 8  
    slli  t2, t0, 24  
    or    t3, t2, t3  
    srli  t2, t0, 8   
    or    t0, t0, t2  
    or    t1, t1, t3
    # x |= (x>>16);
    srli  t3, t1, 16  
    slli  t2, t0, 16  
    or    t3, t2, t3  
    srli  t2, t0, 16   
    or    t0, t0, t2  
    or    t1, t1, t3
    # x |= (x>>32)
    li    t2, 0
    add   t3, t0, zero
    or    t0, t0, t2
    or    t1, t1, t3 
    
    # x -= ((x>>1) & 0x5555555555555555)
    ## [t2, t3] = x>>1 ([t0, t1]>>1)
    srli  t3, t1, 1    
    slli  t2, t0, 31   
    or    t3, t2, t3  
    srli  t2, t0, 1   
    ## (x>>1) & 0x5~
    and   t2, t2, t4
    and   t3, t3, t4        # [t2, t3] = (x>>1)&0x5~
    sub   t3, t1, t3    
    blt   t1, t3, 16    # if underflow then jump
    add   t1, t3, zero    # t1=t3
    sub   t0, t0, t2    # no underflow at lower bits, [t0, t1]=> x -= ((x>>1) & 0x5555555555555555)
    beq   zero, zero, 12
    addi  t0, t0, -1    # underflow at lower bits
    sub   t0, t0, t2        #[t0, t1] => x -= ((x>>1) & 0x5555555555555555) 
    
    # x = ((x>>2)&0x333333333333333) + (x & 0x3333333333333333) 
    ## [t2, t3] = x>>2 ([t0, t1]>>2)
    srli    t3, t1, 2
    slli    t2, t0, 30
    or      t3, t3, t2
    srli    t2, t0, 2    # [t2, t3] = x>>2
    ## (x>>1) & 0x3~
    and     t2, t2, t5
    and     t3, t3, t5    # [t2, t3] = ((x>>2)&0x3~)
    ## x & 0x3~
    and     t0, t0, t5
    and     t1, t1, t5    # [t0, t1] = (x & 0x3~)    
    add     t1, t1, t3
    add     t0, t0, t2
    ## overflow detection (lower bits)
    or t4, t1, zero
    xor t4, s4, t4    # nor t5, t1, zero    (t4 = ~(s4 | zero))
    bgeu t4, t3, 8    # if no overflow then jump
    addi t0, t0, 1    # if overflow upper bits plus 1
    
    # x += ((x>>4)+x) & 0x0f~0f
    ## [t2, t3] = x>>4 ([t0, t1]>>4)
    srli    t3, t1, 4
    slli    t2, t0, 28
    or      t3, t3, t2
    srli    t2, t0, 4
    ## (x>>4) + x
    add t1, t1, t3
    add t0, t0, t2
    ## overflow detection (lower bits)
    or t4, t1, zero
    xor t4, s4, t4    # nor t5, t1, zero    (t4 = ~(s4 | zero))
    bgeu t4, t3, 8    # if no overflow then jump
    addi t0, t0, 1    # if overflow upper bits plus 1
    ## ((x>>4) + x) & 0x0f~0f
    and t0, t0, t6
    and t1, t1, t6

    # x += x(x>>8)
    srli    t3, t1, 8
    slli    t2, t0, 24
    or      t3, t3, t2
    srli    t2, t0, 8    # [t2, t3] = x>>8 
    add     t0, t0, t2
    add     t1, t1, t3
    ## overflow detection
    or      t4, t1, zero
    xor     t4, s4, t4
    bgeu    t4, t3, 8
    addi    t0, t0, 1
    
     # x += x(x>>16)
    srli    t3, t1, 16
    slli    t2, t0, 16
    or      t3, t3, t2
    srli    t2, t0, 16    # [t2, t3] = x>>8 
    add     t0, t0, t2
    add     t1, t1, t3
    ## overflow detection
    or      t4, t1, zero
    xor     t4, s4, t4
    bgeu    t4, t3, 8
    addi    t0, t0, 1
    
    # x += (x>>32)
    add     t3, t0, zero
    add     t2, zero, zero
    add     t0, t0, t2
    add     t1, t1, t3
    ## overflow detection
    or      t4, t1, zero
    xor     t4, s4, t4
    bgeu    t4, t3, 8
    addi    t0, t0, 1
    
    # 64 - (x & (0x7f))
    li      t4, 0x7f   
    li      a0, 64
    and     t1, t1, t4
    sub     a0, a0, t1
    lw      ra, 0(sp)
    addi    sp, sp, 4
    jalr    ra
    

Exit:
    nop
