.data:
   .align 2

	dimension: .word 3 
	matrixA:
			.float 0.0, -2.3, 4.5 
			.float 0x7FC00000, 0x7F800000, 0xFF800000
			.float 3.4, 6.7, 9.9

	matrixB:
			.float 0.0, -2.3, 4.5 
			.float 0x7FC00000, 0x7F800000, 0xFF800000
			.float 3.4, 6.7, 9.9

	matrixC: .space 36
	matrixD: .space 36


    #creo que estas mierdas no van aqui, al tener que acceder a ellas mazo,
    # es mas lento y contraproducente (hay que operar, guardar en la direccion,
    # luego sacralas...  y entre medias usar registers)

    i: .word 0
    j: .word 0

    expMaskA: .space 4 #cual es el tamaño de las masks? 4? puede que sean de tipo .float?
    expMaskB: .space 4

    mantMaskA: .space 4
    mantMaskB: .space 4

.text:
    .globl main
    main:
        #load 4 (word length) into t0
        li $t0 4
        #load the dimension into t1 to operate with it
        lw $t1 dimension
        #as the matrices are square, it means it has (dimension * dimension) elements, obtain it and store it in t1
        mul $t1 $t1 $t1
        #obtain the size of the array by multiplying the number of elements by the word length, and store it in a0 (argument)
        mul $a0 $t0 $t1
        #load the address of the matrixA into a1
        la $a1 matrixA
        #load the address of the matrixB into a2
        la $a2 matrixB
        #call the function addMin
        jal addMin
        #check if the parameter returned in v0 is 0, if not there has been an error (go to the end of the program), falta sacar algo por pantalla
        bnez $v0 end

        #aqui falta el doble for para moverse por las matrices 

        li $t0 0x7F800000
        li $t1 0x007FFFFF

        lw 















    addMin:
        #if(addMin == 0) no ha habido error de procesamiento, else addMin = -1 y
        #se para el programa
        jr $ra

	minFloat:
		#hay que usar el stack y guardar el pc
        jr $ra
	end:
	
