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
        li $t0 4
        #load the dimension into t1 to operate with it
        lw $t1 dimension
        #as the matrices are square, it means it has (dimension * dimension) elements, obtain it and store it in t1
        mul $t1 $t1 $t1
        #obtain the size of the array by multiplying the number of elements by the word length, and store it in a0 (argument)
        mul $a0 $t1 $t0 # 9x4 me da 24... 
        #load the address of the matrixA into a1
        la $a1 matrixA
        #load the address of the matrixB into a2
        la $a2 matrixB
        #call the function addMin
        jal addMin
        #check if the parameter returned in v0 is 0, if not there has been an error (go to the end of the program), falta sacar algo por pantalla
        bnez $v0 end
        #load dimension^2 and aux variable (i)
        lw $t0 i
        lw $t1 dimension
        mul $t1 $t1 $t1
        #load the address of both matrices (is it okay to use s registers?)
        la $s0 matrixA
        la $s1 matrixB

    while: bge $t0 $t1 continue
        #load the word in matrixA and in matrixB
        lw $t2 ($s0)
        lw $t3 ($s1)

        andi $t4 $t2 0x7F800000
        andi $t5 $t3 0x7F800000
        andi $t6 $t2 0x007FFFFF
        andi $t7 $t3 0x007FFFFF


        #aqui van las comparaciones, tengo que pensarme un modo elegante de hacerlas


        #increment the counter by one to check the next element
        addi $t0 $t0 1
        #add 4 to the addres of the matrices to retrieve the next element of each matrix in the next iteration
        addi $s0 $s0 4
        addi $s1 $s1 4
        #go to address while to do the loop again
        b while

    continue:














    addMin:
        #if(addMin == 0) no ha habido error de procesamiento, else addMin = -1 y
        #se para el programa
        li $v0 0
        jr $ra

	minFloat:
            lw $t0, $a0
            sll $t0, $t0, 23
            andi $t0, $t0, 0xff
            li $t1, 0xff
            
            bne $t0, $t1, or1

            lw $t0, $a0
            andi $t0, $t0, 0x7fffff

            bnez $t0, endNan

        or1:
            lw $t0, $a0
            sll $t0, $t0, 23
            andi $t0, $t0, 0xff
            
            bne $t0, $t1, if2

            lw $t0, $a0
            sll $t0, $t0, 31
            andi $t0, $t0, 0x1

            beqz $t0, if2

        endNan:
            li $v0, 0x7FC00000
            jr $ra

        if2:
            lw $t0, $a0
            sll $t0, $t0, 31
            andi $t0, $t0, 0x1
            
            beqz $t0, if3

            lw $t0, $a1
            sll $t0, $t0, 31
            andi $t0, $t0, 0x1

            bnez $t0, if3
	    b endA

        if3:
            lw $t0, $a0
            sll $t0, $t0, 31
            andi $t0, $t0, 0x1
            
            bnez $t0, if4

            lw $t0, $a1
            sll $t0, $t0, 31
            andi $t0, $t0, 0x1

            beqz $t0, if4
	    b endB

        if4:
            lw $t0, $a0
            sll $t0, $t0, 31
            andi $t0, $t0, 0x1
            
            bnez $t0, if5

            slt $t0, $a0, $a1
            bnez $t0, endA
	    b endB
	    
	if5:
	    slt $t0, $a0, $a1
	    beqz $t0, endA
	    b endB
	    
	endNan:
              li $v0, 0x7FC00000
              jr $ra
	endA: move $v0, $a0
	      jr $ra
	endB: move $v0, $a1
	      jr $ra

	end:
	
