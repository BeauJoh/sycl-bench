# An Ubuntu environment configured for building the paper repo.
FROM rocm/dev-ubuntu-18.04

#FROM nvidia/opencl

MAINTAINER Beau Johnston <beau.johnston@anu.edu.au>

ENV DEBIAN_FRONTEND noninteractive

# Setup the environment.
ENV HOME /root
ENV LSB_SRC /libscibench-source
ENV LSB /libscibench
ENV LEVELDB_SRC /leveldb-source
ENV LEVELDB_ROOT /leveldb
ENV OCLGRIND_SRC /oclgrind-source
ENV OCLGRIND /oclgrind
ENV OCLGRIND_BIN /oclgrind/bin/oclgrind
ENV GIT_LSF /git-lsf
ENV PREDICTIONS /opencl-predictions-with-aiwc
ENV EOD /OpenDwarfs
ENV OCL_INC /opt/khronos/opencl/include
ENV OCL_LIB /opt/intel/opencl-1.2-6.4.0.25/lib64
ENV LLVM_SRC_ROOT /downloads/llvm
ENV LLVM_BUILD_ROOT /downloads/llvm-build
ENV COCL /coriander/bin/bin/cocl

# Install essential packages.
RUN apt-get update
RUN apt-get install --no-install-recommends -y software-properties-common \
    ocl-icd-opencl-dev \
    pkg-config \
    build-essential \
    git \
    make \
    zlib1g-dev \
    apt-transport-https \
    dirmngr \
    wget \
    gcc \
    g++

# Install cmake -- newer version than with apt
RUN wget -qO- "https://cmake.org/files/v3.12/cmake-3.12.1-Linux-x86_64.tar.gz" | tar --strip-components=1 -xz -C /usr

# Install OpenCL Device Query tool
RUN git clone https://github.com/BeauJoh/opencl_device_query.git /opencl_device_query

# Install LibSciBench
RUN git clone https://github.com/spcl/liblsb.git $LSB_SRC
WORKDIR $LSB_SRC
RUN ./configure --prefix=$LSB
RUN make
RUN make install

# Install leveldb (optional dependency for OclGrind)
RUN apt update && apt install -y sqlite3
RUN git clone --recursive https://github.com/google/leveldb.git $LEVELDB_SRC
RUN mkdir $LEVELDB_SRC/build
WORKDIR $LEVELDB_SRC/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_INSTALL_PREFIX=$LEVELDB_ROOT
RUN make
RUN make install

# Install LLVM-9.0.1 and clang
WORKDIR /
RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-9.0.1/llvm-9.0.1.src.tar.xz
RUN tar -xvf llvm-9.0.1.src.tar.xz
RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-9.0.1/clang-9.0.1.src.tar.xz
RUN tar -xvf clang-9.0.1.src.tar.xz && mv clang-9.0.1.src clang
#build a shared library version
WORKDIR /llvm-9.0.1.src/build
RUN cmake -DLLVM_ENABLE_PROJECTS=clang -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DCMAKE_ASM_COMPILER=gcc -DBUILD_SHARED_LIBS=On -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/llvm-9.0.1 ..
RUN make -j8 install
RUN make -j8 clang install

##and a dynamic library version
#WORKDIR /llvm-9.0.1.src/dylib_build
#RUN cmake -DLLVM_LINK_LLVM_DYLIB=On -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/llvm-9.0.1 ..
#RUN make -j8 install
#WORKDIR /llvm-9.0.1.src/clang-9.0.1.src/build
#RUN cmake -DLLVM_DIR=/llvm-9.0.1 -DLLVM_BUILD_LLVM_DYLIB=On -DLLVM_LINK_LLVM_DYLIB=On -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/llvm-9.0.1 ..
#RUN make -j8 install

# Install hipify-clang
WORKDIR /
RUN git clone https://github.com/ROCm-Developer-Tools/HIPIFY.git
WORKDIR /HIPIFY/build
RUN cmake  -DCMAKE_INSTALL_PREFIX=/opt/rocm/bin/ -DCMAKE_BUILD_TYPE=Release -DLLVM_SOURCE_DIR=/llvm-9.0.1 -DLLVM_TARGETS_TO_BUILD="X86;NVPTX" ..
RUN make -j8 install

# Pull down coriander
#WORKDIR /coriander
#RUN apt-get update && apt-get install -y --no-install-recommends git gcc g++ libc6-dev zlib1g-dev \
#    libtinfo-dev \
#    curl ca-certificates build-essential wget xz-utils \
#    apt-utils bash-completion
#RUN git clone --recursive https://github.com/beaujoh/coriander -b master
#RUN cd coriander && \
#    mkdir soft
#
## Install LLVM 3.9.0 -- with dynamic libraries
#WORKDIR /coriander/soft
#RUN wget http://releases.llvm.org/3.9.0/llvm-3.9.0.src.tar.xz && tar -xf llvm-3.9.0.src.tar.xz
#WORKDIR /coriander/soft/llvm-3.9.0.src/tools
#RUN wget http://releases.llvm.org/3.9.0/cfe-3.9.0.src.tar.xz && tar -xf cfe-3.9.0.src.tar.xz && mv cfe-3.9.0.src clang
#WORKDIR /coriander/soft/llvm-3.9.0.build
#RUN cmake -DBUILD_SHARED_LIBS=On -DLLVM_BUILD_LLVM_DYLIB=On -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/coriander/soft/llvm-3.9.0.bin /coriander/soft/llvm-3.9.0.src
#RUN make -j32
#RUN make install
#
###Install coriander
#WORKDIR /coriander/build
#RUN cmake /coriander/coriander -DCMAKE_BUILD_TYPE=Debug -DCLANG_HOME=/coriander/soft/llvm-3.9.0.bin -DCMAKE_INSTALL_PREFIX=/coriander/bin && make -j 32 && make install
#RUN apt-get update && apt-get install -y --no-install-recommends gcc-multilib g++-multilib
#RUN wget --directory-prefix=/coriander/bin/include/cocl/ https://raw.githubusercontent.com/llvm-mirror/clang/master/lib/Headers/__clang_cuda_builtin_vars.h
#RUN python3 /coriander/bin/bin/cocl_plugins.py install --repo-url https://github.com/hughperkins/coriander-CLBlast.git
#RUN mv /coriander/bin/lib/coriander_plugins/* /coriander/bin/lib/
#RUN make install

# Install utilities
RUN apt-get install -y --no-install-recommends vim less silversearcher-ag

# Intel CPU OpenCL
#RUN apt-get update -q && apt-get install --no-install-recommends -yq alien wget clinfo \
#    && apt-get clean \
#    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
#RUN export RUNTIME_URL="http://registrationcenter-download.intel.com/akdlm/irc_nas/9019/opencl_runtime_16.1.1_x64_ubuntu_6.4.0.25.tgz" \
#    && export TAR=$(basename ${RUNTIME_URL}) \
#    && export DIR=$(basename ${RUNTIME_URL} .tgz) \
#    && wget -q ${RUNTIME_URL} \
#    && tar -xf ${TAR} \
#    && for i in ${DIR}/rpm/*.rpm; do alien --to-deb $i; done \
#    && rm -rf ${DIR} ${TAR} \
#    && dpkg -i *.deb \
#    && rm *.deb
#RUN mkdir -p /etc/OpenCL/vendors/ \
#    && echo /opt/intel/*/lib64/libintelocl.so > /etc/OpenCL/vendors/intel.icd

###########################################################################
#                         Nvidia OpenCL GPU Driver                        #
###########################################################################
RUN apt-get update && apt-get install -y --no-install-recommends \
        ocl-icd-libopencl1 \
        clinfo && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p /etc/OpenCL/vendors && \
    echo /usr/lib/x86_64-linux-gnu/libnvidia-opencl.so.1 > /etc/OpenCL/vendors/nvidia.icd
# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility


###########################################################################
#                           AMD CPU OpenCL Driver                         #
###########################################################################
RUN apt-get update -q && apt-get install --no-install-recommends -yq wget unzip clinfo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download and setup AMD OpenCL runtime
RUN export SDK_URL="http://www2.ati.com/drivers/linux-amd-14.41rc1-opencl2-sep19.zip" \
    && wget ${SDK_URL} -q -O download.zip --referer support.amd.com \
    && unzip download.zip \
    && rm -f download.zip \
    && bash fglrx-14.41/amd-driver-installer-*.run --extract scratch \
    && export TGT_DIR="/opt/amd/opencl/lib" \
    && mkdir -p $TGT_DIR \
    && cp -r scratch/arch/x86_64/usr/lib64/* "$TGT_DIR" \
    && ln -s "$TGT_DIR/libOpenCL.so.1" "$TGT_DIR/libOpenCL.so" \
    && mkdir -p /etc/OpenCL/vendors/ \
    && echo "$TGT_DIR/libamdocl64.so" > /etc/OpenCL/vendors/amd.icd \
    && rm -rf scratch fglrx*

#NOTE: Both methods of installing the OpenCL CPU driver fail/freeze when allocating a context -- thus we use the AMD instead
###########################################################################
#                         Intel CPU OpenCL Driver                         #
###########################################################################
#WORKDIR /
#RUN git clone https://github.com/stricture/intel-opencl.git
#WORKDIR /intel-opencl
#RUN make install

###########################################################################
#                         Intel CPU OpenCL Driver                         #
###########################################################################
#COPY ./docker-assets/intel_silent_install.cfg /intel_silent_install.cfg
#RUN apt-get update && apt-get install -y cpio
#RUN export RUNTIME_URL="http://registrationcenter-download.intel.com/akdlm/irc_nas/vcp/15532/l_opencl_p_18.1.0.015.tgz" \
#    && export TAR=$(basename ${RUNTIME_URL}) \
#    && export DIR=$(basename ${RUNTIME_URL} .tgz) \
#    && wget -q ${RUNTIME_URL} \
#    && tar -xf ${TAR}\
#    && rm -f /etc/OpenCL/vendors/intel.icd \
#    && ${DIR}/install.sh --silent /intel_silent_install.cfg 
#RUN mkdir -p /etc/OpenCL/vendors/ \
#    && echo /opt/intel/*/lib64/libintelocl.so > /etc/OpenCL/vendors/intel.icd
WORKDIR /tmp
RUN apt-get update && apt-get install -yq cpio lsb-core
RUN wget http://registrationcenter-download.intel.com/akdlm/irc_nas/vcp/15532/l_opencl_p_18.1.0.015.tgz
RUN tar -xvf l_opencl_p_18.1.0.015.tgz
WORKDIR /tmp/l_opencl_p_18.1.0.015/
RUN ./install.sh --silent /intel_silent_install.cfg

###########################################################################
#                                  OneAPI                                 #
###########################################################################
#WORKDIR /oneAPI
#RUN wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2023.PUB && \
# apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2023.PUB
## configure the repository
#ARG apt_repo=https://apt.repos.intel.com/oneapi
#RUN echo "deb $apt_repo all main" > /etc/apt/sources.list.d/oneAPI.list
###cmake > 3.10
#RUN wget -qO - https://apt.kitware.com/keys/kitware-archive-latest.asc | apt-key add -
#RUN apt-add-repository 'deb https://apt.kitware.com/ubuntu/ xenial main'
#RUN apt-get update -y
## install Intel(R) oneAPI Base Toolkit
#RUN apt-get install -y \
#intel-basekit-getting-started \
#intel-oneapi-onevpl-devel-2021.1-beta04 \
#intel-oneapi-onevpl-devel \
#intel-oneapi-common-vars \
#intel-oneapi-common-licensing \
#intel-oneapi-mpi-devel \
#intel-oneapi-ccl \
#intel-oneapi-python \
#intel-oneapi-dnnl-devel \
#intel-oneapi-mkl-devel \
#intel-oneapi-dev-utilities \
#intel-oneapi-daal-devel \
#intel-oneapi-vtune \
#intel-oneapi-ipp-devel \
#intel-oneapi-tbb-devel \
#intel-oneapi-libdpstd-devel \
#intel-oneapi-dpcpp-compiler \
#intel-oneapi-dpcpp-debugger \
#intel-oneapi-advisor


# No AMD devices on this system and their runtime crashes
#ARG HOSTNAME
#RUN if [ "$HOSTNAME" = whale ]; then \
#RUN rm -f /etc/OpenCL/vendors/amdocl64.icd \
#;fi

# OpenMP 
RUN apt-get update && apt-get install -y libomp-dev

# Add Clang to path
ENV PATH "/llvm-9.0.1/bin/:${PATH}"

#
## Setup OpenARC
#RUN apt-get update && apt-get install -yyq openjdk-8-jre openjdk-8-jdk
#ENV OPENARC_ARCH 1
#ENV ACC_DEVICE_TYPE RADEON
#
## Install Pandoc and Latex to build the paper
#RUN apt-get install --no-install-recommends -y lmodern texlive-latex-recommended texlive-fonts-recommended texlive-latex-extra texlive-generic-extra texlive-science texlive-fonts-extra python-pip python-dev
#RUN wget https://bootstrap.pypa.io/ez_setup.py -O - | python
#RUN pip2 install setuptools && pip2 install wheel && pip2 install pandocfilters pandoc-fignos
#WORKDIR /pandoc
#RUN wget https://github.com/jgm/pandoc/releases/download/1.19.2/pandoc-1.19.2-1-amd64.deb && apt-get install -y ./pandoc-1.19.2-1-amd64.deb
#RUN wget https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.0.0/linux-ghc8-pandoc-2-0.tar.gz
#RUN tar -xvf linux-ghc8-pandoc-2-0.tar.gz
#RUN mv pandoc-crossref /usr/bin/
#
#Install hip and ROCm
RUN apt-get update && apt-get install -y kmod
RUN wget -qO - http://repo.radeon.com/rocm/apt/debian/rocm.gpg.key | apt-key add -
RUN echo 'deb [arch=amd64] http://repo.radeon.com/rocm/apt/debian/ xenial main' | tee /etc/apt/sources.list.d/rocm.list
RUN apt-get update
RUN apt-get install --no-install-recommends -y libnuma-dev libunwind-dev rocm-dev


#WORKDIR /rocm
#RUN apt-get update && apt-get install -yqq clang-6.0
#ENV CC /usr/bin/clang-6.0
#ENV CXX /usr/bin/clang-cpp-6.0
#RUN git clone --depth 1 https://github.com/llvm/llvm-project.git
#WORKDIR /rocm/llvm-project/build
#RUN cmake -DCMAKE_INSTALL_PREFIX=/opt/rocm/llvm -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=1 -DLLVM_TARGETS_TO_BUILD="AMDGPU;X86" -DLLVM_EXTERNAL_LLD_SOURCE_DIR=../lld -DLLVM_EXTERNAL_CLANG_SOURCE_DIR=../clang ../llvm
#RUN make -j
#RUN make install

#RUN git clone git@code.ornl.gov:f6l/openarc-openmp.git

#
#WORKDIR /rocm
#RUN git clone -b amd-stg-open https://github.com/RadeonOpenCompute/ROCm-Device-Libs.git
#WORKDIR /rocm/ROCm-Device-Libs
#RUN mkdir -p build
#WORKDIR /rocm/ROCm-Device-Libs/build
#RUN CC=/coriander/soft/llvm-3.9.0.bin/bin/clang CXX=/coriander/soft/llvm-3.9.0.bin/bin/clang++ cmake -DLLVM_DIR=/coriander/soft/llvm-3.9.0.bin -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_WERROR=1 -DLLVM_ENABLE_ASSERTIONS=1 ..
#RUN make -j
#RUN make install

#Install CUDA toolkit (compiler, headers, etc.)
WORKDIR /
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.1.105-1_amd64.deb
RUN echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
RUN apt-get update && apt-get install -yqq cuda-toolkit-10-1
ENV PATH "/usr/local/cuda-10.1/bin:${PATH}"

#Fortran
RUN apt-get update && apt-get install -y gfortran

#disable ROCm opencl driver
RUN rm /etc/OpenCL/vendors/amdocl64.icd

# Install OclGrind
RUN apt-get update && apt-get install --no-install-recommends -y libreadline-dev
RUN git clone --single-branch --branch llvm-9.0.1-shared-libs https://github.com/BeauJoh/Oclgrind.git $OCLGRIND_SRC
RUN mkdir $OCLGRIND_SRC/build
WORKDIR $OCLGRIND_SRC/build
ENV CC /llvm-9.0.1/bin/clang
ENV CXX /llvm-9.0.1/bin/clang++
RUN cmake $OCLGRIND_SRC -DCMAKE_BUILD_TYPE=RelWithDebInfo -DLLVM_DIR=/llvm-9.0.1/lib/cmake/llvm -DCLANG_ROOT=/llvm-9.0.1 -DCMAKE_INSTALL_PREFIX=$OCLGRIND -DBUILD_SHARED_LIBS=On
RUN make
RUN make install
RUN mkdir -p /etc/OpenCL/vendors && echo /oclgrind/lib/liboclgrind-rt-icd.so > /etc/OpenCL/vendors/oclgrind.icd

# Install ComputeCPP
WORKDIR /
RUN wget https://computecpp.codeplay.com/downloads/computecpp-ce/latest/ubuntu-16.04-64bit.tar.gz
RUN rm -rf /tmp/ComputeCpp-latest && mkdir /tmp/ComputeCpp-latest/
RUN tar -xzf ubuntu-16.04-64bit.tar.gz -C /tmp/ComputeCpp-latest --strip-components 1

# Install triSYCL
RUN wget https://github.com/triSYCL/triSYCL/archive/master.zip -O /tmp/trisycl.zip
RUN unzip /tmp/trisycl.zip -d /tmp  &> /dev/null

# Install DPC++
# Note we require two separate builds -- one for each back-end (OpenCL or CUDA)
RUN apt-get install ninja-build
RUN wget https://github.com/intel/llvm/archive/sycl.zip -O /tmp/llvm-sycl.zip
RUN unzip /tmp/llvm-sycl.zip -d /tmp
RUN cp -r /tmp/llvm-sycl /tmp/llvm-sycl-cuda
WORKDIR /tmp/llvm-sycl/build
RUN CC=gcc CXX=g++ python /tmp/llvm-sycl/buildbot/configure.py
RUN python /tmp/llvm-sycl/buildbot/compile.py
WORKDIR /tmp/llvm-sycl-cuda/build
RUN CC=gcc CXX=g++ CMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs python /tmp/llvm-sycl-cuda/buildbot/configure.py --cuda
RUN python /tmp/llvm-sycl-cuda/buildbot/compile.py

#Install hipSYCL
WORKDIR /tmp
RUN git clone --recurse-submodules https://github.com/illuhad/hipSYCL.git
WORKDIR /tmp/hipSYCL/install/scripts
RUN apt-get update && apt-get install -y gawk iputils-ping gawk rsync libnuma-dev libpci-dev libelf-dev perl perl-modules
#because ./install-rocm breaks we install hipSYCL through the uni-heidelberg package manager and the cuda backend with their script --due to licensing.
RUN echo "deb http://repo.urz.uni-heidelberg.de/sycl/deb/ ./bionic main" > /etc/apt/sources.list.d/hipsycl.list
RUN wget -q -O - http://repo.urz.uni-heidelberg.de/sycl/hipsycl.asc | apt-key add -
RUN apt-get update && apt-get install -y hipsycl-rocm
RUN sh ./install-llvm.sh && sh ./install-cuda.sh && sh ./install-hipsycl.sh

#Install sycl-gtx
#WORKDIR /tmp
#RUN git clone https://github.com/ProGTX/sycl-gtx.git
#WORKDIR /tmp/sycl-gtx/build
#RUN CC=gcc CXX=g++ cmake .. -DCMAKE_INSTALL_PREFIX=/tmp/sycl-gtx
#RUN make -j8 && make install

# Compile sycl-bench
#WORKDIR /
#RUN git clone https://github.com/bcosenza/sycl-bench.git

# build with ComputeCPP
#WORKDIR /sycl-bench/ComputeCPP-build
#RUN cmake ../ -DSYCL_IMPL=ComputeCpp -DCMAKE_PREFIX_PATH=/tmp/ComputeCpp-latest -DCMAKE_INSTALL_PREFIX=/workspace/codes/sycl-bench/bin/benchmarks
#RUN make -j8

# build with DPC++
#WORKDIR /sycl-bench/build-dpc++
#cmake ../ -DSYCL_IMPL=LLVM -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DDPC++_INSTALL_DIR=/tmp/llvm-sycl/build/install
# make --keep-going

# build with DPC++(CUDA)
#WORKDIR /sycl-bench/build-dpc++-cuda
#cmake ../ -DSYCL_IMPL=LLVM-CUDA  -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DDPC++_INSTALL_DIR=/tmp/llvm-sycl-cuda/build/install
# make --keep-going

# build with hipSYCL
##cpu
#WORKDIR /workspace/codes/sycl-bench/build-hipsycl-cpu
#RUN cmake ../ -DSYCL_IMPL=hipSYCL  -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DhipSYCL_DIR=/opt/hipSYCL/lib/cmake -DHIPSYCL_PLATFORM=cpu
#RUN make
##cuda
#WORKDIR /workspace/codes/sycl-bench/build-hipsycl-cuda
#RUN cmake ../ -DSYCL_IMPL=hipSYCL  -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DhipSYCL_DIR=/opt/hipSYCL/lib/cmake -DHIPSYCL_PLATFORM=cuda -DHIPSYCL_GPU_ARCH=sm_60
#RUN make
##rocm
#WORKDIR /workspace/codes/sycl-bench/build-hipsycl-rocm
#RUN cmake ../ -DSYCL_IMPL=hipSYCL  -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DhipSYCL_DIR=/opt/hipSYCL/lib/cmake -DHIPSYCL_PLATFORM=rocm -DHIPSYCL_GPU_ARCH=gfx906
#RUN make

# build with triSYCL
RUN apt-get install -y libboost-all-dev libtbb-dev g++-9 clang-9
#WORKDIR /workspace/codes/sycl-bench/build-trisycl
#RUN cmake ../ -DSYCL_IMPL=triSYCL -DTRISYCL_TBB=ON -DTRISYCL_INCLUDE_DIR=/tmp/triSYCL-master/include
#RUN make

# build with sycl-gtx
#WORKDIR /workspace/codes/sycl-bench/build-sycl-gtx
#RUN cmake ../ -DSYCL_IMPL=sycl-gtx -DSYCL-GTX_DIR=/tmp/sycl-gtx
#RUN make

# Install beakerx
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 51716619E084DAB9 && add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran40/'
RUN apt-get update && apt-get install --no-install-recommends -y libreadline-dev libpcre3-dev libbz2-dev liblzma-dev python3.6-dev r-base curl libcurl4-openssl-dev libxml2-dev libssl-dev  liblapack-dev libopenblas-dev

RUN wget https://bootstrap.pypa.io/get-pip.py && python3 ./get-pip.py
RUN pip3 install --upgrade pip
RUN pip3 install tzlocal rpy2 requests beakerx ipywidgets pandas py4j
RUN Rscript -e "install.packages('devtools')"\
     && Rscript -e "devtools::install_github('IRkernel/IRkernel')"\
     && Rscript -e "IRkernel::installspec(user = FALSE)"\
     && Rscript -e "devtools::install_github('cran/RJSONIO')"\
     && Rscript -e "devtools::install_github('r-lib/httr')"\
     && Rscript -e "devtools::install_github('tidyverse/magrittr')"\
     && Rscript -e "install.packages('ggplot2')"\
     && Rscript -e "devtools::install_github('tidyverse/tidyr')"\
     && Rscript -e "devtools::install_github('BeauJoh/fmsb')"\
     && Rscript -e "devtools::install_github('cran/gridGraphics')"\
     && Rscript -e "devtools::install_github('cran/Metrics')"\
     && Rscript -e "devtools::install_github('cran/latex2exp')"\
     && Rscript -e "devtools::install_github('cran/akima')" \
     && Rscript -e "devtools::install_github('cran/pander')"\
     && Rscript -e "devtools::install_github('cran/gtools')"\
     && Rscript -e "devtools::install_github('wilkelab/cowplot')"\
     && Rscript -e "install.packages('viridis')"
RUN beakerx install

#openssl required for hashing AIWC kernels in IRIS
RUN apt-get update && apt-get install -y libssl-dev

#predictive model dependencies
RUN Rscript -e "install.packages('devtools')" \
    && Rscript -e "devtools::install_github('imbs-hl/ranger')" \
    && Rscript -e "devtools::install_github('cran/RJSONIO')"\
    && Rscript -e "devtools::install_github('RcppCore/Rcpp')" \
    && Rscript -e "install.packages('tidyverse')" \
    && Rscript -e "devtools::install_github('cran/Metrics')" \
    && Rscript -e "install.packages('testit')" \
    && Rscript -e "install.packages('data.table')"

#dependencies for scripts to regenerate the model
RUN pip3 install pyopencl tqdm
RUN git clone https://github.com/spcl/liblsb.git /lsb-source
WORKDIR /lsb-source
RUN ./configure --prefix=/lsb && make && make install

#dependencies to query the model from C++
RUN Rscript -e "install.packages('RInside')"

#experimental plotting resources
RUN Rscript -e "install.packages('latex2exp')" &&\
    Rscript -e "install.packages('breakDown')" &&\
    Rscript -e "install.packages('filesstrings')" &&\
    Rscript -e "install.packages('ggpubr')"
RUN apt install -yq libudunits2-dev libmagick++-dev libgdal-dev
RUN install.packages("remotes") &&\
    remotes::install_github("coolbutuseless/ggpattern")

#WORKDIR /
#RUN git clone https://github.com/bcosenza/sycl-bench.git

#Test by default
WORKDIR /workspace
CMD /bin/bash

#ENV LD_LIBRARY_PATH "${LD_LIBRARY_PATH}/root/.local/lib64"
#ENV CPATH "${CPATH}:/root/.local/include"
#ENV LIBRARY_PATH "${LIBRARY_PATH}:/root/.local/lib64"
#CMD ldconfig && ./build.sh && /bin/bash

#add the following command for model regeneration
#CMD cd /workspace/collect-model-data && ./autogen.sh && mkdir build && cd build && ../configure --with-libscibench=/lsb && make && python3 ../opendwarf_miner.py

