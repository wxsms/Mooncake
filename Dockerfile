FROM hub-mirror.wps.cn/kas-open/base/pytorch/pytorch:2.5.1-cuda12.4-cudnn9-devel-git

# install etcd
RUN apt update && \
    apt install -y build-essential \
                            cmake \
                            libibverbs-dev \
                            libgoogle-glog-dev \
                            libgtest-dev \
                            libjsoncpp-dev \
                            libnuma-dev \
                            libpython3-dev \
                            libboost-all-dev \
                            libssl-dev \
                            libgrpc-dev \
                            libgrpc++-dev \
                            libprotobuf-dev \
                            protobuf-compiler-grpc \
                            pybind11-dev && \
    apt install -y etcd && \
    apt clean && rm -rf /var/lib/apt/lists/*

RUN apt update && \
    apt install -y infiniband-diags perftest ibverbs-providers libibumad3 libibverbs1 libnl-3-200 libnl-route-3-200 librdmacm1 && \
    apt clean && rm -rf /var/lib/apt/lists/*

# build mooncake deps
COPY Mooncake/thirdparties /workspace/Mooncake/thirdparties
COPY Mooncake/dependencies.sh /workspace/Mooncake/dependencies.sh
RUN cd /workspace/Mooncake && bash dependencies.sh

# install vllm
COPY vllm-1.0.0.dev-cp38-abi3-manylinux1_x86_64.whl /tmp/vllm-1.0.0.dev-cp38-abi3-manylinux1_x86_64.whl
WORKDIR /workspace
RUN pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple && \
    pip install -U pip setuptools wheel && \
    pip install /tmp/vllm-1.0.0.dev-cp38-abi3-manylinux1_x86_64.whl && \
    pip install quart && \
    pip install "fastapi[standard]" && \
    pip cache purge && \
    rm /tmp/vllm-1.0.0.dev-cp38-abi3-manylinux1_x86_64.whl

# build mooncake
COPY Mooncake /workspace/Mooncake
WORKDIR /workspace/Mooncake
ENV LIBRARY_PATH=/usr/local/cuda/lib64${LIBRARY_PATH:+:${LIBRARY_PATH}}
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

RUN mkdir build && \
    cd build && \
    cmake -DUSE_CUDA=ON .. && \
    make -j4 && \
    make install

# build vllm
COPY vllm /workspace/vllm
WORKDIR /workspace
RUN cd vllm python python_only_dev.py

# done
WORKDIR /workspace
ENTRYPOINT []
