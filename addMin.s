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

    i: .word 0
    j: .word 0

    expMaskA:
    expMaskB:

    mantMaskA:
    mantMaskB:

.text:
    .globl main
    main:
        #call the function addMin
        jal addMin


    addMin:
        #if(addMin == 0) no ha habido error de procesamiento, else addMin = -1 y
        #se para el programa
        jr $ra

	minFloat:
		#hay que usar el stack y guardar el pc
        jr $ra
	
	
