#include <stdio.h>
#include <stdlib.h>

int N; 

/* function declaration */
float min(float numbMatA, float numbMatB);

int main(int argc, char *argv[]){

	// Define constants (IEEE 754 bit patterns in hex)
	#define HEX_VALUE_OF_NAN 0x7FC00000
	#define HEX_VALUE_OF_POS_INF 0x7F800000
	#define HEX_VALUE_OF_NEG_INF 0xFF800000
	#define HEX_VALUE_OF_MIN_SUB_NUM 0x00000001
	#define HEX_VALUE_OF_MAX_SUB_NUM 0x007FFFFF
	#define HEX_VALUE_OF_POS_ZERO 0x00000000
	#define HEX_VALUE_OF_NEG_ZERO 0x80000000

	// Declare variables
	int i,j;

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
	printf("\nOpening input files\n");
	finputA = fopen(argv[2], "r");
	finputB = fopen(argv[3], "r");

	// If the first file is not found, stop the program, else load it to the matrixA and then close the file
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

	// If the second file is not found, stop the program, else load it to the matrixB and then close the file
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

	// Conditions for filling C[][]
	for(i = 0; i<N; i++){
		for(j = 0; j<N; j++){

			//Esto son los punteros a la direccion de memoria donde se encuentra el elemento i j de la matriz que estan casteados a numero entero sin signo, 
			// es decir, se obtiene el valor en entero sin signo guardado direccion de memoria del elemento de la matriz
			unsigned int* ptrToMatrixA = (unsigned int*)&A[i][j];
			unsigned int* ptrToMatrixB = (unsigned int*)&B[i][j];
			unsigned int* ptrToMatrixC = (unsigned int*)&C[i][j];

			// 1. If A[i][j] == ±0 or B[i][j]== ±0, then C[i][j] = +0
			if(*ptrToMatrixA == HEX_VALUE_OF_NEG_ZERO || *ptrToMatrixA == HEX_VALUE_OF_POS_ZERO || *ptrToMatrixB == HEX_VALUE_OF_NEG_ZERO || *ptrToMatrixB == HEX_VALUE_OF_POS_ZERO){
				*ptrToMatrixC = HEX_VALUE_OF_POS_ZERO;
			}

			// 2. Else if A[i][j] == NaN or B[i][j]== NaN, then C[i][j] = NaN
			else if(*ptrToMatrixA == HEX_VALUE_OF_NAN || *ptrToMatrixB == HEX_VALUE_OF_NAN){
				*ptrToMatrixC = HEX_VALUE_OF_NAN;
			}

			// 3. Else if A[i][j] == ±Inf or B[i][j]== ±Inf, then C[i][j] = NaN
			else if(*ptrToMatrixA == HEX_VALUE_OF_POS_INF || *ptrToMatrixA == HEX_VALUE_OF_NEG_INF || *ptrToMatrixB == HEX_VALUE_OF_POS_INF || *ptrToMatrixB == HEX_VALUE_OF_NEG_INF){
				*ptrToMatrixC = HEX_VALUE_OF_NAN;
			}

			// 4. Else if A[i][j] stores a non-normalized (0 is considered as normalized) and B[i][j] stores a non-normalized number as well, then C[i][j]=0
			else if((*ptrToMatrixA <= HEX_VALUE_OF_MAX_SUB_NUM && *ptrToMatrixA >= HEX_VALUE_OF_MIN_SUB_NUM) && (*ptrToMatrixB <= HEX_VALUE_OF_MAX_SUB_NUM && *ptrToMatrixB >= HEX_VALUE_OF_MIN_SUB_NUM)){
				*ptrToMatrixC = HEX_VALUE_OF_POS_ZERO;
			}

			// 5. Else if A[i][j] stores a non-normalized (0 is considered as normalized) and B[i][j] stores a normalized one, then C[i][j]=B[i][j]
			else if((*ptrToMatrixA <= HEX_VALUE_OF_MAX_SUB_NUM && *ptrToMatrixA >= HEX_VALUE_OF_MIN_SUB_NUM) && (*ptrToMatrixB >= HEX_VALUE_OF_MAX_SUB_NUM || *ptrToMatrixB <= HEX_VALUE_OF_MIN_SUB_NUM)){
				C[i][j] = B[i][j];

			}
			// 6. Else if A[i][j] stores a normalized number (0 is considered as normalized) and B[i][j] stores a non-normalized one, then C[i][j]=A[i][j]
			else if((*ptrToMatrixA >= HEX_VALUE_OF_MAX_SUB_NUM || *ptrToMatrixA <= HEX_VALUE_OF_MIN_SUB_NUM) && (*ptrToMatrixB <= HEX_VALUE_OF_MAX_SUB_NUM && *ptrToMatrixB >= HEX_VALUE_OF_MIN_SUB_NUM)){
				C[i][j] = A[i][j];
			}
			//7. Else, in any other case, if A[i][j] stores a normalized value and B[i][j] too (0 is considered as normalized), C[i][j]=A[i][j] + B[i][j].
			else{
				C[i][j] = A[i][j] + B[i][j];
			}

			// Calculate D[][] using the "min" function
			D[i][j] = min(A[i][j],B[i][j]);
		}
	}

	// Create output file from C[][]
	printf("Creating outputC.txt...\n");

	foutputC = fopen("outputC.txt", "w");

	if(!foutputC){
		printf("Error while creating outputC.txt\n");
		return -1;
	}
	for(i = 0; i<N; i++){
		for(j = 0; j<N; j++){
			fprintf(foutputC, "%g ", C[i][j]);
		}
		fprintf(foutputC, "\n");
	}


	// Create output file from D[][]
	printf("Creating outputD.txt...\n");

	foutputD = fopen("outputD.txt", "w");

	if(!foutputD){
		printf("Error while creating outputD.txt\n");
		return -1;
	}
	// Prints output matrix created in fileD
	for(i = 0; i<N; i++){
		for(j = 0; j<N; j++){
			fprintf(foutputD, "%g ", D[i][j]);
		}
		fprintf(foutputD, "\n");
	}

	return 0;
}

// Function returning the min between two numbers 
float min(float numbMatA, float numbMatB){

	//Esto son los punteros a la direccion de memoria donde se encuentra el elemento i j de la matriz que estan casteados a numero entero sin signo, 
	// es decir, se obtiene el valor en entero sin signo guardado direccion de memoria del elemento de la matriz
	unsigned int* ptrToMatrixA = (unsigned int*)&numbMatA;
	unsigned int* ptrToMatrixB = (unsigned int*)&numbMatB;

	//if *ptrToMatrixA is negative and *ptrToMatrixB is negative
	//if *ptrToMatrixA is positive and *ptrToMatrixB is negative
	//if *ptrToMatrixA is negative and *ptrToMatrixB is positive
	//else they are both positive

	if(((*ptrToMatrixA & (1 << 31)) == 1) && ((*ptrToMatrixB & (1 << 31)) == 1)){
		if(*ptrToMatrixA < *ptrToMatrixB){
			return numbMatB;
		}
		else
			return numbMatA;
	}
	
	else if(((*ptrToMatrixA & (1 << 31)) == 0) && ((*ptrToMatrixB & (1 << 31)) == 1)){
		return numbMatB;
	}
	else if(((*ptrToMatrixA & (1 << 31)) == 1) && ((*ptrToMatrixB & (1 << 31)) == 0)){
		return numbMatA;
	}
	else{
		if(*ptrToMatrixA < *ptrToMatrixB){
			if(*ptrToMatrixB == HEX_VALUE_OF_NAN || *ptrToMatrixB == HEX_VALUE_OF_NEG_INF || *ptrToMatrixA == HEX_VALUE_OF_POS_INF){
				return numbMatB;
			}
			//interesante para comentar en el paper, si devuelves el ptr, hay error en el numero
			return numbMatA;
		}

		if(*ptrToMatrixA > *ptrToMatrixB){
			if (*ptrToMatrixA == HEX_VALUE_OF_NAN || *ptrToMatrixA == HEX_VALUE_OF_NEG_INF || *ptrToMatrixB == HEX_VALUE_OF_POS_INF){
				return numbMatA;
			}
			return numbMatB;
		}
		else
			//When they are equal
			return numbMatB;
	}
}
