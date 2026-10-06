#include <stdio.h>
#include <cuda_runtime.h>

// Macro to catch CUDA errors 
#define CHECK_CUDA(call) \
do { \
    cudaError_t err = call; \
    if (err != cudaSuccess) { \
        printf("CUDA error at %s %d: %s\n", __FILE__, __LINE__, \
               cudaGetErrorString(err)); \
        exit(EXIT_FAILURE); \
    } \
} while (0)

// CUDA kernel for parallel fold (reduction)
__global__ void sumReduction(unsigned long long *input, unsigned long long *total_sum, int n) {
    // Dynamic shared memory allocated per block
    extern __shared__ unsigned long long sdata[];

    unsigned int tid = threadIdx.x;
    unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;

    // Load data into shared memory, padding with 0s if out of bounds
    sdata[tid] = (i < n) ? input[i] : 0;
    __syncthreads();

    // Perform tree reduction (fold) in shared memory
    for (unsigned int s = blockDim.x / 2; s > 0; s >>= 1) {
        if (tid < s) {
            sdata[tid] += sdata[tid + s];
        }
        __syncthreads();
    }

    // Thread 0 of each block atomically adds the block's sum to the global total
    if (tid == 0) {
        atomicAdd(total_sum, sdata[0]);
    }
}

int main() {
    const int N = 1000000;
    const int threadsPerBlock = 256;
    const int blocks = (N + threadsPerBlock - 1) / threadsPerBlock;

    size_t inputSize = N * sizeof(unsigned long long);
    
    // Allocate host memory
    unsigned long long *h_input = (unsigned long long*)malloc(inputSize);
    unsigned long long h_total_sum = 0;

    // Initialize array with 1 to N
    for (int i = 0; i < N; ++i) {
        h_input[i] = i + 1;
    }

    // Allocate device memory
    unsigned long long *d_input, *d_total_sum;
    CHECK_CUDA(cudaMalloc(&d_input, inputSize));
    CHECK_CUDA(cudaMalloc(&d_total_sum, sizeof(unsigned long long)));

    // Copy data to device and initialize total_sum to 0
    CHECK_CUDA(cudaMemcpy(d_input, h_input, inputSize, cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemset(d_total_sum, 0, sizeof(unsigned long long)));

    // Launch kernel with dynamic shared memory
    size_t sharedMemSize = threadsPerBlock * sizeof(unsigned long long);
    sumReduction<<<blocks, threadsPerBlock, sharedMemSize>>>(d_input, d_total_sum, N);
    
    // Check for kernel launch errors and sync
    CHECK_CUDA(cudaGetLastError());
    CHECK_CUDA(cudaDeviceSynchronize());

    // Copy result back to host
    CHECK_CUDA(cudaMemcpy(&h_total_sum, d_total_sum, sizeof(unsigned long long), cudaMemcpyDeviceToHost));

    // Calculate expected sum using math: N * (N + 1) / 2
    unsigned long long expected_sum = (unsigned long long)N * (N + 1) / 2;

    printf("GPU Sum:      %llu\n", h_total_sum);
    printf("Expected Sum: %llu\n", expected_sum);

    if (h_total_sum == expected_sum) {
        printf("SUCCESS: Container and GPU are working correctly!\n");
    } else {
        printf("FAILED: Sums do not match.\n");
    }

    // Cleanup
    cudaFree(d_input);
    cudaFree(d_total_sum);
    free(h_input);

    return 0;
}