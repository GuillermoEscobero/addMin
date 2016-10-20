#include <stdio.h>
#include <stdlib.h>

// Define constants (IEEE 754 bit patterns in hex)
#define HEX_VALUE_OF_NAN 0x7FC00000
#define HEX_VALUE_OF_POS_INF 0x7F800000
#define HEX_VALUE_OF_POS_ZERO 0x00000000

int N; 

/* function declaration */
float min(float numbMatA, float numbMatB);

int main(int argc, char *argv[]){

	// Declare variables
	int i,j;
	int expMaskA, mantMaskA;
	int expMaskB, mantMaskB;


	float **A, **B, **C, **D;

	FILE *finputA;
	FILE *finputB;
	FILE *foutputC;
	FILE *foutputD;

	// Checks if the number of arguments introduced in the command line is correct
    if (argc != 6){
        printf("The number of arguments introduced is wrong\n");
        
        return -1;
    }

	// Casting matrix range argument to int
	sscanf(argv[1],"%d", &N);

	// Allocate memory for the matrices
	A = (float **) malloc(N * sizeof(float *));
	B = (float **) malloc(N * sizeof(float *));
	C = (float **) malloc(N * sizeof(float *));
	D = (float **) malloc(N * sizeof(float *));

 	//Allocate memory for the rows of each matrix
	for(i = 0; i < N; i++){
		A[i] = (float *) malloc(N * sizeof(float));
		B[i] = (float *) malloc(N * sizeof(float));
		C[i] = (float *) malloc(N * sizeof(float));
		D[i] = (float *) malloc(N * sizeof(float));
	}

	// Open input files
	printf("\nOpening input files... ");
	finputA = fopen(argv[2], "r");
	finputB = fopen(argv[3], "r");

	// If the first file is not found, stop the program,
	// else load it to the matrixA and then close the file

	if(finputA == NULL){
		printf("Error while opening the first file.\n");

		return -1;
	}else{
		for(i = 0; i<N; i++){
			for(j = 0; j<N; j++){
				if(!fscanf(finputA, "%g", &A[i][j])){
					break;
				}
			}
		}
	}
	fclose(finputA);

	// If the second file is not found, stop the program,
	// else load it to the matrixB and then close the file

	if(finputB == NULL){
		printf("Error while opening the second file.\n");

		return -1;
	}else{
		for(i = 0; i<N; i++){
			for(j = 0; j<N; j++){
				if(!fscanf(finputB, "%g", &B[i][j])){
					break;
				}
			}
		}
	}
	fclose(finputB);
	printf("Done!\n");

	// Conditions for filling C
	printf("Computing conditions... ");
	for(i = 0; i<N; i++){
		for(j = 0; j<N; j++){

			// Esto son los punteros a la direccion de memoria donde se encuentra
			// el elemento i j de la matriz que estan casteados a numero entero 
			// sin signo, es decir, se obtiene el valor en entero sin signo guardado
			// en la direccion de memoria del elemento de la matriz
			unsigned int* ptrToMatrixA = (unsigned int*)&A[i][j];
			unsigned int* ptrToMatrixB = (unsigned int*)&B[i][j];
			unsigned int* ptrToMatrixC = (unsigned int*)&C[i][j];
			unsigned int* ptrToMatrixD = (unsigned int*)&D[i][j];

			expMaskA = *ptrToMatrixA & 0x7F800000;
			expMaskB = *ptrToMatrixB & 0x7F800000;
			mantMaskA = *ptrToMatrixA & 0x007FFFFF;
			mantMaskB = *ptrToMatrixB & 0x007FFFFF;

			// 1. If A[i][j] == ±0 or B[i][j]== ±0, then C[i][j] = +0
			if((expMaskA == 0 && mantMaskA == 0) || (expMaskB == 0 && mantMaskB == 0)) {
				*ptrToMatrixC = HEX_VALUE_OF_POS_ZERO;
			}

			// 2. Else if A[i][j] == NaN or B[i][j]== NaN, then C[i][j] = NaN
			// 3. Else if A[i][j] == ±Inf or B[i][j]== ±Inf, then C[i][j] = NaN
			else if(expMaskA == 0x7F800000 || expMaskB == 0x7F800000) {
				*ptrToMatrixC = HEX_VALUE_OF_NAN;
			}

			// 4. Else if A[i][j] stores a non-normalized (0 is considered as normalized) 
			// and B[i][j] stores a non-normalized number as well, then C[i][j]=0
			// 5. Else if A[i][j] stores a non-normalized (0 is considered as normalized)
			// and B[i][j] stores a normalized one, then C[i][j]=B[i][j]
			else if(expMaskA == 0 && mantMaskA != 0) {
				if(expMaskB == 0 && mantMaskB != 0) {
					*ptrToMatrixC = HEX_VALUE_OF_POS_ZERO;
				}else if(expMaskB != 0) {
					C[i][j] = B[i][j];
				}
			}

			// 6. Else if A[i][j] stores a normalized number (0 is considered as normalized)
			// and B[i][j] stores a non-normalized one, then C[i][j]=A[i][j]
			// 7. Else, in any other case, if A[i][j] stores a normalized value
			// and B[i][j] too (0 is considered as normalized), C[i][j]=A[i][j] + B[i][j].
			else if(expMaskA != 0){
				if (expMaskB == 0 && mantMaskB != 0){
					C[i][j] = A[i][j];
				}else if(expMaskB == 0 && mantMaskB != 0) {
					C[i][j] = A[i][j] + B[i][j];
				}
			}

			// Calculate D[][] using the "min" function
			D[i][j] = min(A[i][j],B[i][j]);
		}
	}

	printf("Done!\n");

	// Create output file from matC

	printf("Creating %s... ", argv[4]);
	foutputC = fopen(argv[4], "w");
	if(!foutputC){
		printf("Error while creating %s\n", argv[4]);
		return -1;
	}

	// Prints output matrix created in fileC
	for(i = 0; i<N; i++){
		for(j = 0; j<N; j++){
			fprintf(foutputC, "%g ", C[i][j]);
		}
		fprintf(foutputC, "\n");
	}
	fclose(foutputC);
	printf("Done!\n");


	// Create output file from matrix D
	printf("Creating %s... ", argv[5]);
	foutputD = fopen(argv[5], "w");
	if(!foutputD){
		printf("Error while creating %s\n", argv[5]);
		return -1;
	}

	// Prints output matrix created in fileD
	for(i = 0; i<N; i++){
		for(j = 0; j<N; j++){
			fprintf(foutputD, "%g ", D[i][j]);
		}
		fprintf(foutputD, "\n");
	}
	fclose(foutputD);
	printf("Done!\n");

	// Free memory
	for (i = 0; i < N; i++){
 		free(A[i]);
 		free(B[i]);
 		free(C[i]);
 		free(D[i]);
	}
	free(A);
	free(B);
	free(C);
	free(D); 

	printf("Program successfully executed. Check %s and %s!\n", argv[4],argv[5]);
	return 0;
}

// Function returning the min between two numbers 
float min(float numbMatA, float numbMatB){
	unsigned int* ptrToNumbMatA = (unsigned int*)&numbMatA;
	unsigned int* ptrToNumbMatB = (unsigned int*)&numbMatB;

	int expMaskA  = *ptrToNumbMatA & 0x7F800000;
	int expMaskB  = *ptrToNumbMatB & 0x7F800000;
	int mantMaskA = *ptrToNumbMatA & 0x007FFFFF;
	int mantMaskB = *ptrToNumbMatB & 0x007FFFFF;
	int signMaskA = *ptrToNumbMatA & 0x80000000;
	int signMaskB = *ptrToNumbMatB & 0x80000000;

	// Case: one of the two values is NaN
	if((expMaskA == 0x7F800000 && mantMaskA != 0) || (expMaskB == 0x7F800000 && mantMaskB != 0)){
		int hexNanValue = 0x7F800000;
		float nanValue = (*(int*)&hexNanValue);
		return nanValue;
	}

	if(signMaskA == 0x80000000 && signMaskB == 0){        // - +
		return numbMatA;
	}else if(signMaskA == 0 && signMaskB == 0x80000000){  // + -
		return numbMatB;
	}else if(signMaskA == 0){							  // + +
		if(*ptrToNumbMatA < *ptrToNumbMatB){
			return numbMatA;
		}else{
			return numbMatB;
		}
	}else{												  // - -
		if(*ptrToNumbMatA < *ptrToNumbMatB){
			return numbMatB;
		}else{
			return numbMatA;
		}
	}

}


