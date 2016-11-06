#include <stdio.h>
#include <stdlib.h>

/*
* Lab assignment 1: Introduction to C & Assembly
* addMin.c
* Recieves two files with a float matrix. Compares them, and
* depending on the inputs, it generates an output file C and
* an output file D
*
* @author Guillermo Escobero & Raul Olmedo
* @args range, inputFile1, inputFile2, outputFile1, outputFile2
*/

// Define constants (IEEE 754 bit patterns in hexadecimal).
#define HEX_VALUE_OF_NAN 0x7FC00000
#define HEX_VALUE_OF_POS_INF 0x7F800000
#define HEX_VALUE_OF_POS_ZERO 0x00000000


// Function declaration.
float min(float numbMatA, float numbMatB);

int main(int argc, char *argv[]){

	// Declare variables

	int n; //Used to store the matrix range given in the first argument.
	int i,j; //Used to iterate in matrix.

	// Used to store the result after applying the properly bitmask to an
	// element of the matrix.
	int expMaskA, mantMaskA;
	int expMaskB, mantMaskB;

	// Declaration of matrixes.
	float **A, **B, **C, **D;

	// Declaration of file streams, for reading A and B, and writing C and D.
	FILE *finputA;
	FILE *finputB;
	FILE *foutputC;
	FILE *foutputD;

	// Checks if the number of arguments introduced is correct.
	if (argc != 6){
		printf("ERROR: The number of arguments introduced (%d)", (argc-1));
		printf(" is wrong!\n");
		printf("Only 5 arguments are accepted (dimension of the matrix,");
		printf(" inputFile1, inputFile2, outputFile1, outputFile2)\n");
		exit(EXIT_FAILURE);
	}

	// Casting matrix range argument (char) to int.
	n = atoi(argv[1]);

	if(n == 0){ // atoi returns 0 if the conversion fails.
		printf("ERROR: the range introduced (%s)", argv[1]);
		printf(" is not valid\n");
		exit(EXIT_FAILURE);
	}

	// Allocate memory for the matrices.
	A = (float **) malloc(n * sizeof(float *));
	B = (float **) malloc(n * sizeof(float *));
	C = (float **) malloc(n * sizeof(float *));
	D = (float **) malloc(n * sizeof(float *));

 	// Allocate memory for the rows of each matrix.
	for(i = 0; i < n; i++){
		A[i] = (float *) malloc(n * sizeof(float));
		B[i] = (float *) malloc(n * sizeof(float));
		C[i] = (float *) malloc(n * sizeof(float));
		D[i] = (float *) malloc(n * sizeof(float));
	}

	// Open file streams (input matrix files).
	printf("\nOpening input files... ");
	//Open file stream of file given on the second argument (fileA).
	finputA = fopen(argv[2], "r");
	//Open file stream of tile given on the third  argument (fileB).
	finputB = fopen(argv[3], "r");

	// Scans the first file and stores the values in A.
	if(finputA == NULL){
		// File or directory given in second argument not found.
		printf("\nError opening %s: No such file or directory\n", argv[2]);
		exit(EXIT_FAILURE);
	}else{
		int counter = -1; //Counts the number of elements read from fileA.
		for(i = 0; ; i++){
			for(j = 0; j<n; j++){
				if(feof(finputA)){
					// If file stream has reached the end of the file,
					// program goes out the nested loops.
					goto out;
				// This read the float value and stores it in A[i][j].
				}else if(!fscanf(finputA, "%f", &A[i][j])){
					// If fscanf fails, it means that a
					// value read is not float-type. Then, the program fails.
					printf("\nERROR: an input value in %s is not float\n", argv[2]);
					exit(EXIT_FAILURE);
				}else{
					// If code reaches this, the element has been read
					// successfully, so counter is incremented by 1.
					counter++;
				}
			}
		}
		out: // Label used to go out nested for-loops.

		// Compares if the elements in the file can be stored in a matrix 
		// with the range provided in the first argument. If it does not
		// exactly fits, programs fails.
		if(counter != n*n){
			printf("\nERROR: number of elements in %s (%d) does not", argv[2],counter);
			printf(" fit in the matrix range provided (%s).\n", argv[1]);
			exit(EXIT_FAILURE);
		}
	}
	fclose(finputA); // Closes the file stream.


	// Scans the first file and stores the values in B.
	// *This block has the same structure as the previous one,
	//  so comments are omitted.
	if(finputB == NULL){
		printf("\nError opening %s: No such file or directory\n", argv[3]);
		exit(EXIT_FAILURE);
	}else{
		int counter = -1;
		for(i = 0; ; i++){
			for(j = 0; j<n; j++){
				if(feof(finputB)){
						goto out2;
				}else if(!fscanf(finputB, "%f", &B[i][j])) {
						printf("\nERROR: an input value in %s is not float\n", argv[3]);
						exit(EXIT_FAILURE);
				}else{
					counter++;
				}
			}
		}
		out2:
		if(counter != n*n){
			printf("\nERROR: number of elements in %s (%d) does not", argv[3],counter); 
			printf(" fit in the matrix range provided (%s).\n", argv[1]);
			exit(EXIT_FAILURE);
		}
	}
	fclose(finputB);

	printf("Done!\n"); //Indicates that the load of files is completed successfully.

	// Conditions for filling C.
	printf("Computing conditions... ");
	// Nested for-loops to go over matrixes.
	for(i = 0; i<n; i++){
		for(j = 0; j<n; j++){

			// Pointer of type int to the current element of each matrix.
			// With this, we get the full bit pattern (IEEE 754 format) of the float value.
			unsigned int* ptrToMatrixA = (unsigned int*)&A[i][j];
			unsigned int* ptrToMatrixB = (unsigned int*)&B[i][j];
			unsigned int* ptrToMatrixC = (unsigned int*)&C[i][j];

			// Getting result of applying bitmask to the current element of each matrix
			expMaskA = *ptrToMatrixA & 0x7F800000; //0111111110000...
			expMaskB = *ptrToMatrixB & 0x7F800000;
			mantMaskA = *ptrToMatrixA & 0x007FFFFF;//0000000001111...
			mantMaskB = *ptrToMatrixB & 0x007FFFFF;

			// 1. If A[i][j] == ±0 or B[i][j]== ±0, then C[i][j] = +0

			// The bit pattern of 0 are 10000... or 00000... 
			// Its exponent is 0 and its mantissa is also 0
			if(  (expMaskA == 0 && mantMaskA == 0) 
			  || (expMaskB == 0 && mantMaskB == 0)) {
				// Changes the value of the element (C[i][j]) with the bit pattern
				// of +0 (IEEE 754 format).
				*ptrToMatrixC = HEX_VALUE_OF_POS_ZERO;
			}

			// 2. Else if A[i][j] == NaN or B[i][j]== NaN, then C[i][j] = NaN
			// 3. Else if A[i][j] == ±Inf or B[i][j]== ±Inf, then C[i][j] = NaN

			// As Nan and +-inf has 11111111 in their exponent, only one comparison is needed.
			else if(expMaskA == 0x7F800000 || expMaskB == 0x7F800000) {
				// Changes the value of the pointer (C[i][j]) with the bit pattern
				// of NaN (IEEE 754 format).
				*ptrToMatrixC = HEX_VALUE_OF_NAN;
			}

			// 4. Else if A[i][j] stores a non-normalized (0 is considered as normalized)
			// and B[i][j] stores a non-normalized number as well, then C[i][j]=0
			// 5. Else if A[i][j] stores a non-normalized (0 is considered as normalized)
			// and B[i][j] stores a normalized one, then C[i][j]=B[i][j]

			// A normalized number is the number that its exponent is equal to 0, with
			// its mantissa different from 0.
			else if(expMaskA == 0) { // If A[i][j] is non-normalized.
				if(expMaskB == 0) { // If B[i][j] is also non-normalized.
					// Changes the value of the element (C[i][j]) with the bit pattern
					// of +0 (IEEE 754 format).
					*ptrToMatrixC = HEX_VALUE_OF_POS_ZERO;
				}else{ // If B[i][j] is normalized.
					C[i][j] = B[i][j];
				}
			}

			// 6. Else if A[i][j] stores a normalized number (0 is considered as normalized)
			// and B[i][j] stores a non-normalized one, then C[i][j]=A[i][j]
			// 7. Else, in any other case, if A[i][j] stores a normalized value
			// and B[i][j] too (0 is considered as normalized), C[i][j]=A[i][j] + B[i][j].

			// A normalized number is the number that its exponent is equal to 0, with
			// its mantissa different from 0.
			else if(expMaskA != 0){ // If A[i][j] is normalized
				if (expMaskB == 0){ // If B[i][j] is non-normalized.
					C[i][j] = A[i][j];
				}else{ // If B[i][j] is also normalized.
					C[i][j] = A[i][j] + B[i][j];
				}
			}

			// Calculate D[i][j] using the "min" function.
			D[i][j] = min(A[i][j],B[i][j]);
		}
	}

	printf("Done!\n"); //Indicates that comparison of matrixes is completed successfully.

	// Creates output file from matrix C.

	printf("Creating %s... ", argv[4]);

	//Opens file stream for the output file given on the fourth argument (fileC).
	foutputC = fopen(argv[4], "w");

	// If fileC cannot be created, throws an error and exit the program.
	if(foutputC == NULL){
		printf("\nERROR: creating output file %s failed!\n", argv[4]);
		exit(EXIT_FAILURE);
	}

	// Writes output matrix created in fileC.
	for(i = 0; i<n; i++){
		for(j = 0; j<n; j++){
			fprintf(foutputC, "%g ", C[i][j]);
		}
	}
	fclose(foutputC);
	printf("Done!\n");


	// Create output file from matrix D.

	printf("Creating %s... ", argv[5]);
	foutputD = fopen(argv[5], "w");

	if(foutputD == NULL){
		printf("\nERROR: creating output file %s failed!\n", argv[5]);
		exit(EXIT_FAILURE);
	}

	// Writes output matrix created in fileD.
	for(i = 0; i<n; i++){
		for(j = 0; j<n; j++){
			fprintf(foutputD, "%g ", D[i][j]);
		}
	}
	fclose(foutputD);
	printf("Done!\n");

	// Frees memory used by the four matrixes.
	for (i = 0; i < n; i++){
 		free(A[i]);
 		free(B[i]);
 		free(C[i]);
 		free(D[i]);
	}
	free(A);
	free(B);
	free(C);
	free(D); 

	printf("Program successfully executed.");
	printf(" Check %s and %s!\n", argv[4],argv[5]);
	
	exit(EXIT_SUCCESS); // Return 0;
}

/*
 * Function:  min(float numbMatA, float numbMatB)
 * --------------------
 * Calculates the minimum of two float values.
 *
 *  numbMatA: first float value.
 *  numbMatb: second float value.
 *
 *  returns: the minimum of the float values provided in the arguments.
 */
float min(float numbMatA, float numbMatB){

	// With this, we get the full bit pattern (IEEE 754 format) of the float value.
	unsigned int* ptrToNumbMatA = (unsigned int*)&numbMatA;
	unsigned int* ptrToNumbMatB = (unsigned int*)&numbMatB;

	// Applies bitmasking
	int expMaskA  = *ptrToNumbMatA & 0x7F800000; //0111111110...
	int expMaskB  = *ptrToNumbMatB & 0x7F800000; //0111111110...
	int mantMaskA = *ptrToNumbMatA & 0x007FFFFF; //0000000001...
	int mantMaskB = *ptrToNumbMatB & 0x007FFFFF; //0000000001...
	int signMaskA = *ptrToNumbMatA & 0x80000000; //1000000000...
	int signMaskB = *ptrToNumbMatB & 0x80000000; //1000000000...

	// Case: one of the two values is NaN.
	// (The exponent of NaN is 11111111 (0x7F800000),
	// and the mantissa is different from 0)
	if(  (expMaskA == 0x7F800000 && mantMaskA != 0) 
	  || (expMaskB == 0x7F800000 && mantMaskB != 0)){
		int hexNanValue = HEX_VALUE_OF_NAN;
		// Casting from bit pattern in an int variable to float IEEE 754:
		float nanValue = *((float*)&hexNanValue);
		return nanValue;
	}

	// In IEEE 754 format, if the first bit is 0, the number is positive,
	// and if it is 1, the number is negative.

	// If numbMatA is negative and numbMatB is positive.
	if(signMaskA == 0x80000000 && signMaskB == 0){
		return numbMatA;// The minimum is numbMatA.
	// If numbMatA is positive and numbMatB is negative.
	}else if(signMaskA == 0 && signMaskB == 0x80000000){
		return numbMatB;// The minimum is numbMatB.
	// If numbMatA is positive and numbMatB is positive also.
	}else if(signMaskA == 0){
		if(*ptrToNumbMatA < *ptrToNumbMatB){
			return numbMatA;
		}else{
			return numbMatB;
		}
	}else{// If numbMatA is negative and numbMatB is negative also.
		// The minimum of two negative numbers: max(abs(a),(abs(b))).
		if(*ptrToNumbMatA < *ptrToNumbMatB){
			return numbMatB;
		}else{
			return numbMatA;
		}
	}

}


