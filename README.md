# Development Container for CUDA

## Notes
- zsh is configured as a nice shell, bash is pretty default

## Usage

`ctrl+shift+p` then run `Dev Containers: Rebuild Without Cache and Reopen in Container`

To check it
```
⬢ [podman] ❯ nvcc -o check_cuda check_cuda.cu 

gpu-devenv on  main 
⬢ [podman] ❯ ./check_cuda 
GPU Sum:      500000500000
Expected Sum: 500000500000
SUCCESS: Container and GPU are working correctly!
```
