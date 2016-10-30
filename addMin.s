.data
   .align 2

	dimension: .word 3 
	matrixA:
			.float 0.0, -2.3, 4.5 
			.word 0x7FC00000, 0x7F800000, 0xFF800000 #aqui si pongo .float estalla
			.float 3.4, 6.7, 9.9

	matrixB:
			.float 0.0, -2.3, 4.5 
			.word 0x7FC00000, 0x7F800000, 0xFF800000
			.float 3.4, 6.7, 9.9

	matrixC: .space 36
	matrixD: .space 36


    #creo que estas mierdas no van aqui, al tener que acceder a ellas mazo,
    # es mas lento y contraproducente (hay que operar, guardar en la direccion,
    # luego sacralas...  y entre medias usar registers)

    i: .word 0
    k: .word 0

    expMaskA: .space 4 #cual es el tamaño de las masks? 4? puede que sean de tipo .float?
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

    while: bge $s0 $s1 continue
        #load the word of matrixA and in matrixB
        l.s $f0 ($s2)
        l.s $f1 ($s3)

        #move from FPU to CPU 
        mfc1 $t6 $f0 
        mfc1 $t7 $f1 

        #save the hex values of all 1s in mantissa and all 1s in the exponent to obtain later the masks
        li $t8 0x7F800000
        li $t9 0x007FFFFF

        #masks of exp and mant
        and $t0 $t6 $t8
        and $t1 $t7 $t8
        and $t2 $t6 $t9
        and $t3 $t7 $t9

        # 1. If A[i][j] == ±0 or B[i][j]== ±0, then C[i][j] = +0
        or $t2 $t0 $t2
        or $t3 $t1 $t3
        and $t2 $t2 $t3
        beqz $t2 setMatrixCTo0

        # 2. Else if A[i][j] == NaN or B[i][j]== NaN, then C[i][j] = NaN
        # 3. Else if A[i][j] == ±Inf or B[i][j]== ±Inf, then C[i][j] = NaN
        and $t2 $t0 $t8
        and $t3 $t1 $t8            
        or $t2 $t2 $t3
        beqz $t2 setMatrixCToNaN

        # 4. Else if A[i][j] stores a non-normalized (0 is considered as normalized) 
        # and B[i][j] stores a non-normalized number as well, then C[i][j]=0
        # 5. Else if A[i][j] stores a non-normalized (0 is considered as normalized)
        # and B[i][j] stores a normalized one, then C[i][j]=B[i][j]
        and $t2 $t0 1
        beqz $t2 checkExpMaskOfB

        # 6. Else if A[i][j] stores a normalized number (0 is considered as normalized)
        # and B[i][j] stores a non-normalized one, then C[i][j]=A[i][j]
        # 7. Else, in any other case, if A[i][j] stores a normalized value
        # and B[i][j] too (0 is considered as normalized), C[i][j]=A[i][j] + B[i][j].
        and $t2 $t1 1
        beqz $t2 setMatrixCtoMatrixA
        la $t6 matrixC
        add $t7 $s2 $s3 
        sw $t7 ($t6)
        b increment

    increment:
        #increment the counter by one to check the next element
        addi $s0 $s0 1
        #add 4 to the addres of the matrices to retrieve the next element of each matrix in the next iteration
        addi $s2 $s2 4
        addi $s3 $s3 4
        #go to address while to do the loop again
        b while

    setMatrixCTo0: 
        la $t6 matrixC
        sw $zero ($t6)
        b increment

    setMatrixCToNaN:
        la $t6 matrixC
        li $t7 0x7FC00000
        sw $t7 ($t6)
        b increment

    checkExpMaskOfB:
        and $t3 $t1 1 
        beqz $t3 setMatrixCTo0
        la $t6 matrixC
        sw $s3 ($t6)
        b increment

    setMatrixCtoMatrixA:
        la $t6 matrixC
        sw $s2 ($t6)
        b increment

    continue:
        jal minFloat









    addMin:
        #if(addMin == 0) no ha habido error de procesamiento, else addMin = -1 y
        #se para el programa
        li $v0 0
        jr $ra

	minFloat:
		#hay que usar el stack y guardar el pc
        jr $ra




	end:
	
