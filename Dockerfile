# 1. NVIDIA's official CUDA Devel image withnvcc compiler
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    cmake \
    build-essential \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN git clone --recursive https://github.com/leejet/stable-diffusion.cpp

WORKDIR /app/stable-diffusion.cpp
RUN mkdir build
WORKDIR /app/stable-diffusion.cpp/build


# 75 = RTX 20-series (Turing)
# 86 = RTX 30-series / A4000 / A5000 / A6000 (Ampere)
# 89 = RTX 40-series / RTX 6000 Ada / RTX 4000 SFF Ada (Ada Lovelace)
# SD_CUBLAS=ON
RUN cmake .. -DSD_CUDA=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_ARCHITECTURES="75;86;89" && \
    cmake --build . --config Release -- -j$(nproc)

# 6. Install the binary globally
RUN cp /app/stable-diffusion.cpp/build/bin/sd /usr/local/bin/sd

# 7. Setup Workspace for RunPod
WORKDIR /workspace

# 8. Keep the container alive for Web Terminal
CMD ["sleep", "infinity"]
