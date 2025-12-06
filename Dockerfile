FROM nvidia/cuda:12.2.0-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build tools
RUN apt-get update && apt-get install -y \
    git cmake build-essential libcurl4-openssl-dev \
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

# -------------------------------------------------------------------
# STAGE 2: RUNTIME
# -------------------------------------------------------------------
FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Runtime Deps + Python + Pip
RUN apt-get update && apt-get install -y \
    wget curl git libgomp1 libcurl4 \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 2. Install Hugging Face Hub & hf_transfer (for fast downloads)
RUN pip3 install -U "huggingface_hub"

# 3. Copy the compiled binary
COPY --from=builder /app/stable-diffusion.cpp/build/bin/sd /usr/local/bin/sd

# 4. Set up Workspace
WORKDIR /workspace

# 5. Copy the startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 6. Default Command
CMD ["/start.sh"]
