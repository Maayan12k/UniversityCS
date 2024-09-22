#include<stdio.h>
#include<stdlib.h>
#include<sys/time.h>

/**
  *  Must use cudaDeviceSynchronize() when measuring GPU kernel operations because they are non blocking. 
 */
double myCPUTimer(){ 
    struct timeval tp;
    gettimeofday(&tp, NULL);
    return ((double)tp.tv_sec + (double)tp.tv_usec/1.0e6);
}

void vecAdd_h(float* x_h, float* y_h, float* z_h, unsigned int n){
    for(unsigned int i = 0; i < n; i++)
        z_h[i] = x_h[i] + y_h[i];
}

__global__ void vecAddKernel(float* x_d, float* y_d, float* z_d, unsigned int n) {
    int i = blockDim.x*blockIdx.x + threadIdx.x;
    if(i < n) // handling boundary conditions
        z_d[i] = x_d[i] + y_d[i];
}

int main(int argc, char** argv){

    unsigned int n = 1024;

    //allocate host memory for x_h, y_h, and z_h and intialize x_h, y_h
    float* x_h = (float*) malloc(sizeof(float)*n);
    for(unsigned int i = 0; i < n; i++) x_h[i] = (float) rand()/(float)(RAND_MAX);
    float* y_h = (float*) malloc(sizeof(float)*n);
    for(unsigned int i = 0; i < n; i++) y_h[i] = (float) rand()/(float)(RAND_MAX);
    float* z_h = (float*) calloc(n, sizeof(float));

    // (1) allocate device memory for arrays x_d, y_d, z_d
    float *x_d, *y_d, *z_d;
    cudaMalloc((void**) &x_d, sizeof(float)*n);
    cudaMalloc((void**) &y_d, sizeof(float)*n);
    cudaMalloc((void**) &z_d, sizeof(float)*n);

    // (2) copy arrays x_h and y_h to device memory x_d and y_d, respectively
    cudaMemcpy(x_d, x_h, sizeof(float)*n, cudaMemcpyHostToDevice);
    cudaMemcpy(y_d, y_h, sizeof(float)*n, cudaMemcpyHostToDevice);

    // (3) call kernel to launch a grid of threads to perform the vector addition on GPU && CPU
    double startTime_h = myCPUTimer();
    vecAdd_h(x_h, y_h, z_h, n);
    double endTime_h = myCPUTimer();
    printf("Execution time of CPU 1024 Vector addition: %f\n", endTime_h - startTime_h);

    double startTime_d = myCPUTimer();
    vecAddKernel<<<ceil(n/256.0), 256>>>(x_d, y_d, z_d, n);
    cudaDeviceSynchronize();
    double endTime_d = myCPUTimer();
    printf("Execution time of GPU 1024 Vector addition: %f\n", endTime_d - startTime_d);

    // (4) Copy the result data from device memory of array  z_d to host memory of array z_h
    cudaMemcpy(z_h, z_d, sizeof(float)*n, cudaMemcpyDeviceToHost);

    // (5) free device memory of x_d, y_d, and z_d 
    cudaFree(x_d);
    cudaFree(y_d);
    cudaFree(z_d);

    // free host memory of x_h, z_h, and z_h
    free(x_h);
    free(y_h);
    free(z_h);

    return 0;
}
