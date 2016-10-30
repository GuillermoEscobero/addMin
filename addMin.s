.data
   .align 2

	dimension: .word 3 
	matrixA:
			.float 0.0, -2.3, 4.5 
			.word 0x7FC00000, 0x7F800000, 0xFF800000
			.float 3.4, 6.7, 9.9

	matrixB:
			.float 0.0, -2.3, 4.5 
			.word 0x7FC00000, 0x7F800000, 0xFF800000
			.float 3.4, 6.7, 9.9

	matrixC: .space 36
	matrixD: .space 36

    i: .word 0

    expMaskA: .space 4
    expMaskB: .space 4

    mantMaskA: .space 4
    mantMaskB: .space 4

.text
    .globl main
    main:
        #load 4 (word length) into t0
        li $s0 4
        #load the dimension into t1 to operate with it
        lw $s1 dimension
        #as the matrices are square, it means it has (dimension * dimension) elements, obtain it and store it in t1
        mul $s1 $s1 $s1
        #obtain the size of the array by multiplying the number of elements by the word length, and store it in a0 (argument)
        mul $a0 $s1 $s0
        #load the address of the matrixA into a1
        la $a1 matrixA
        #load the address of the matrixB into a2
        la $a2 matrixB
        #call the function addMin
        jal addMin
        #check if the parameter returned in v0 is 0, if not there has been an error (go to the end of the program), falta sacar algo por pantalla
        bnez $v0 end
        #load dimension^2 and aux variable (i)
        lw $s0 i
        lw $s1 dimension
        mul $s1 $s1 $s1
        #load the address of both matrices (do i have to do this or do i pass it through the standard paramteres registers?
        la $s2 matrixA
        la $s3 matrixB
        #load matrixC address
        la $s4 matrixC
        la $s5 matrixD

    while: bge $s0 $s1 continue
        #load the word of matrixA and in matrixB
        l.s $f0 ($s2)
        l.s $f1 ($s3)

        #move from FPU to CPU in order to compare them
        mfc1 $t6 $f0 
        mfc1 $t7 $f1 

        #save the hex values of all 1s in mantissa and all 1s in the exponent to obtain later the masks
        li $t4 0x7F800000
        li $t5 0x007FFFFF

        #masks of exp and mant
        and $t0 $t6 $t4
        and $t1 $t7 $t4
        and $t2 $t6 $t5
        and $t3 $t7 $t5

        # 1. If A[i][j] == ±0 or B[i][j]== ±0, then C[i][j] = +0
        or $t8 $t0 $t2
        or $t9 $t1 $t3
        and $t8 $t8 $t9
        beqz $t8 setMatrixCTo0

        # 2. Else if A[i][j] == NaN or B[i][j]== NaN, then C[i][j] = NaN
        # 3. Else if A[i][j] == ±Inf or B[i][j]== ±Inf, then C[i][j] = NaN
        beq $t0 $t4 setMatrixCToNaN
        beq $t1 $t4 setMatrixCToNaN

        # 4. Else if A[i][j] stores a non-normalized (0 is considered as normalized) 
        # and B[i][j] stores a non-normalized number as well, then C[i][j]=0
        # 5. Else if A[i][j] stores a non-normalized (0 is considered as normalized)
        # and B[i][j] stores a normalized one, then C[i][j]=B[i][j]
        and $t8 $t0 0xFFFFFFFF
        beqz $t8 checkExpMaskOfB

        # 6. Else if A[i][j] stores a normalized number (0 is considered as normalized)
        # and B[i][j] stores a non-normalized one, then C[i][j]=A[i][j]
        # 7. Else, in any other case, if A[i][j] stores a normalized value
        # and B[i][j] too (0 is considered as normalized), C[i][j]=A[i][j] + B[i][j].
        and $t8 $t1 0xFFFFFFFF
        beqz $t8 setMatrixCtoMatrixA
        l.s $f0 ($s2)
        l.s $f1 ($s3)
        add.s $f0 $f0 $f1
        s.s $f0 ($s4)
        b increment

    increment:
        #move the float values to the registers used to pass parameters
        mov.s $f12 $f0
        mov.s $f14 $f1
        #call the function minFloat
        jal minFloat
        #store in matrixD the number in $f0 (returning value of minFloat)
        l.s $f0 ($s5)
        #increment the counter by one to check the next element
        addi $s0 $s0 1
        #add 4 to the addres of the matrices to retrieve the next element of each matrix in the next iteration
        addi $s2 $s2 4
        addi $s3 $s3 4
        addi $s4 $s4 4
        addi $s5 $s5 4
        #go to address while to do the loop again
        b while

    setMatrixCTo0: 
        sw $zero ($s4)
        b increment

    setMatrixCToNaN:
        li $t0 0x7FC00000
        mtc1 $t0 $f0
        cvt.s.w $f0 $f0
        s.s $f0 ($s4)
        b increment

    checkExpMaskOfB:
        and $t3 $t1 0x7FC00000
        beqz $t3 setMatrixCTo0
        l.s $f0 ($s3)
        s.s $f0 ($s4)
        b increment

    setMatrixCtoMatrixA:
        l.s $f0 ($s2)
        s.s $f0 ($s4)
        b increment

    addMin:
        #if(addMin == 0) no ha habido error de procesamiento, else addMin = -1 y
        #se para el programa
        li $v0 0
        jr $ra

	minFloat:
        #store the registers that will be used in the stack and restore at the end //TODO
        cvt.w.s $f0 $f12
        mfc1 $t0 $f0

        cvt.w.s $f1 $f14
        mfc1 $t1 $f1

        #save the hex values of all 1s in mantissa and all 1s in the exponent to obtain later the masks
        li $s2 0x7F800000
        li $s3 0x007FFFFF
        li $s4 0x80000000

        #calculate the masks
        and $t2 $s2 $t0 
        and $t3 $s2 $t1
        and $t4 $s3 $t0
        and $t5 $s3 $t1
        and $t6 $s4 $t0
        and $t7 $s4 $t1

    if1:
        beq $t2 $s2 checkMantMaskOfA
        beq $t3 $s2 checkMantMaskOfB

    if2:
        beq $t6 $s4 checkSignMaskB

    if3: 
        beqz $t6 checkSignMaskB

    if4: 
        beqz $t6 compareValues

        bgt $t1 $t0 returnNumbB
        b returnNumbA
    
	checkMantMaskOfA:
        bnez $t4 returnNaN
        b if2

    checkMantMaskOfB:
        bnez $t5 returnNaN
        b if2

    checkSignMaskB:
        beqz $t7 returnNumbA
        beq $t7 $s4 returnNumbB
        b if3

    compareValues:
        bgt $t1 $t0 returnNumbA
        b returnNumbB


    returnNaN:
        li $t0 0x7FC00000
        mtc1 $t0 $f0
        cvt.s.w $f0 $f0
        jr $ra

    returnNumbA:
        mtc1 $t0 $f0
        cvt.s.w $f0 $f0
        jr $ra
        
    returnNumbB:
        mtc1 $t1 $f0
        cvt.s.w $f0 $f0
        jr $ra

    continue:
        jr $ra
	end:
        jr $ra
