.data
   .align 2

	dimension: .word 3 
	matrixA:
			.word 0x80000000, 0x7fffffff, 0xff800000
			.float 25.0, 5.877472e-39, 2.0
			.float 5.877472e-39, 1.0, 0.0

	matrixB:
			.float 2.0, 5.0, 52.0 
			.float 3.2, 5.877472e-39, 2.0
			.float 2.0, 5.877472e-39, 0.0

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
        #check if the parameter returned in v0 is 0, if not there has been an error (go to the error of the program)
        bnez $v0 error
        #load aux variable (i)
        lw $s0 i
        #load dimension and then multiply by itself to obtain the total number of elements per matrix
        lw $s1 dimension
        #obtain the total 
        mul $s1 $s1 $s1
        #load the address of both matrices A and B (do i have to do this or do i pass it through the standard paramteres registers?
        la $s2 matrixA
        la $s3 matrixB
        #load matrixC address
        la $s4 matrixC
        #load matrixD address
        la $s5 matrixD

    while: bge $s0 $s1 end
        #load the float in matrixA and matrixB
        l.s $f0 ($s2)
        l.s $f1 ($s3)

        #move from FPU to CPU in order to compare them
        mfc1 $t6 $f0 
        mfc1 $t7 $f1 

        #save the hex values of all 1s in mantissa and all 1s in the exponent to obtain later the masks
        li $t4 0x7F800000
        li $t5 0x007FFFFF

        #masks of exp and mant
        and $t0 $t6 $t4 #exponent mask of A
        and $t1 $t7 $t4 #exponent mask of B
        and $t2 $t6 $t5 #mantissa mask of A
        and $t3 $t7 $t5 #mantissa mask of B

        # 1. If A[i][j] == ±0 or B[i][j]== ±0, then C[i][j] = +0
        or $t8 $t0 $t2
        or $t9 $t1 $t3
        beqz $t8 setMatrixCTo0
        beqz $t9 setMatrixCTo0

        # 2. Else if A[i][j] == NaN or B[i][j]== NaN, then C[i][j] = NaN
        # 3. Else if A[i][j] == ±Inf or B[i][j]== ±Inf, then C[i][j] = NaN
        beq $t0 $t4 setMatrixCToNaN
        beq $t1 $t4 setMatrixCToNaN

        # 4. Else if A[i][j] stores a non-normalized (0 is considered as normalized) 
        # and B[i][j] stores a non-normalized number as well, then C[i][j]=0
        # 5. Else if A[i][j] stores a non-normalized (0 is considered as normalized)
        # and B[i][j] stores a normalized one, then C[i][j]=B[i][j]
        beqz $t0 checkExpMaskOfB

        # 6. Else if A[i][j] stores a normalized number (0 is considered as normalized)
        # and B[i][j] stores a non-normalized one, then C[i][j]=A[i][j]
        and $t8 $t1 0x7F800000
        beqz $t8 setMatrixCtoMatrixA

        # 7. Else, in any other case, if A[i][j] stores a normalized value
        # and B[i][j] too (0 is considered as normalized), C[i][j]=A[i][j] + B[i][j].
        l.s $f0 ($s2)
        l.s $f1 ($s3)
        add.s $f0 $f0 $f1
        s.s $f0 ($s4)
        #increment the addresses and aux variable (i)
        b increment

    increment:
        #move the float values to the registers used to pass parameters
        mov.s $f12 $f0
        mov.s $f14 $f1
        #call the function minFloat
        jal minFloat
        #store in matrixD the number in $f0 (returning value of minFloat)
        s.s $f0 ($s5)
        #increment the counter by one to check the next element
        addi $s0 $s0 1
        #add 4 to the addres of the matrices to retrieve the next element of each matrix in the next iteration
        addi $s2 $s2 4
        addi $s3 $s3 4
        addi $s4 $s4 4
        addi $s5 $s5 4
        #go to address 'while' to do the loop again
        b while

    setMatrixCTo0:
        #store 0 into matrixC 
        sw $zero ($s4)
        b increment

    setMatrixCToNaN:
        li $t0 0x7FC00000
        #move the word to the FPU
        mtc1 $t0 $f0
        #convert the word to float
        cvt.s.w $f0 $f0
        #store the word in matrixC
        s.s $f0 ($s4)
        b increment

    checkExpMaskOfB:
        beqz $t1 setMatrixCTo0
        #load the value of matrixB
        l.s $f0 ($s3)
        #store the value to matrixC
        s.s $f0 ($s4)
        b increment

    setMatrixCtoMatrixA:
        #load the value of matrixA
        l.s $f0 ($s2)
        #store the value to matrixC
        s.s $f0 ($s4)
        b increment

    addMin:
        #if(addMin == 0) no ha habido error de procesamiento, else addMin = -1 y
        #se para el programa
        li $v0 0
        jr $ra

	minFloat:
        #store the registers that will be used in minFloat in the stack
        sub $sp $sp 12
        sw $s2 8($sp)
        sw $s3 4($sp)
        sw $s4 0($sp)
        #convert the parameter received to word type
        cvt.w.s $f0 $f12
        #move from FPU to CPU
        mfc1 $t0 $f0
        #convert the parameter received to word type
        cvt.w.s $f1 $f14
        #move from FPU to CPU
        mfc1 $t1 $f1

        #save the hex values of all 1s in mantissa, all 1s in the exponent and all 1s in the sign to obtain later the masks
        li $s2 0x7F800000
        li $s3 0x007FFFFF
        li $s4 0x80000000

        #calculate the masks
        and $t2 $s2 $t0 #exponent mask of A
        and $t3 $s2 $t1 #exponent mask of B
        and $t4 $s3 $t0 #mantissa mask of A
        and $t5 $s3 $t1 #mantissa mask of B
        and $t6 $s4 $t0 #sign mask of A
        and $t7 $s4 $t1 #sign mask of B

    if1:
        #if exponent mask of A equals 0x7F800000 go to checkMantMaskOfA 
        beq $t2 $s2 checkMantMaskOfA
        #if exponent mask of B equals 0x7F800000 go to checkMantMaskOfB 
        beq $t3 $s2 checkMantMaskOfB

    if2:
        #if sign mask of A equals 0x80000000 go to checkSignMaskB
        beq $t6 $s4 checkSignMaskB

    if3: 
        #if sign mask of A equals 0 go to checkSignMaskB
        beqz $t6 checkSignMaskB

    if4: 
        #if sign mask of A equals 0 go to compareValues
        beqz $t6 compareValues
        #if the value in matrixB is greater than the one in matrixA, go to returnNumbB
        bgt $t1 $t0 returnNumbB
        #else go to returnNumbA
        b returnNumbA
    
	checkMantMaskOfA:
        #if mantissa mask of A is not 0, go to returnNaN
        bnez $t4 returnNaN
        #else go to if2 and continue checkign conditions
        b if2

    checkMantMaskOfB:
        #if mantissa mask of B is not 0, go to returnNaN
        bnez $t5 returnNaN
        #else go to if2 and continue checkign conditions
        b if2

    checkSignMaskB:
        #if sign mask of B is 0, go to returnNumbA
        beqz $t7 returnNumbA
        #if sign mask of B is 0x80000000, go to returnNumbB
        beq $t7 $s4 returnNumbB
        #else go to if3 and continue checking conditions 
        b if3

    compareValues:
        #if the value in matrixB is greater than the one in matrixA, go to returnNumbA
        bgt $t1 $t0 returnNumbA
        #else go to returnMatB
        b returnNumbB

    returnNaN:
        #load the hex value of NaN
        li $t0 0x7FC00000
        #move it to FPU
        mtc1 $t0 $f0
        #convert from word to float 
        cvt.s.w $f0 $f0
        #restore the registers used in the function to their previous values
        lw $s4 ($sp)
        lw $s3 4($sp)
        lw $s2 8($sp)
        #move the stack pointer address to delete the stored registers
        add $sp $sp 12
        #return to the next line after this function call
        jr $ra

    returnNumbA:
        #move to the FPU the value of matrixA
        mtc1 $t0 $f0
        #convert it from word to float
        cvt.s.w $f0 $f0
        #restore the registers used in the function to their previous values
        lw $s4 ($sp)
        lw $s3 4($sp)
        lw $s2 8($sp)
        #move the stack pointer address to delete the stored registers
        add $sp $sp 12
        #return to the next line after this function call
        jr $ra
        
    returnNumbB:
        #move to the FPU the value of matrixB
        mtc1 $t1 $f0
        #convert it from word to float
        cvt.s.w $f0 $f0
        #restore the registers used in the function to their previous values
        lw $s4 ($sp)
        lw $s3 4($sp)
        lw $s2 8($sp)
        #move the stack pointer address to delete the stored registers
        add $sp $sp 12
        #return to the next line after this function call
        jr $ra

    error:
        #TODO
        jr $ra

    end:
        #end of program
        li $v0 10
        syscall
