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

# SD_CUBLAS=ON
RUN cmake .. -DSD_CUBLAS=ON -DCMAKE_BUILD_TYPE=Release && \
    cmake --build . --config Release -- -j$(nproc)

# 6. Install the binary globally
RUN cp /app/stable-diffusion.cpp/build/bin/sd /usr/local/bin/sd

# 7. Setup Workspace for RunPod
WORKDIR /workspace

# 8. Keep the container alive for Web Terminal
CMD ["sleep", "infinity"]
