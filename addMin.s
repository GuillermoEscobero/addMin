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

.text:
	#esto es un textp de prueba
	