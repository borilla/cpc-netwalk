FROM mcr.microsoft.com/devcontainers/base:ubuntu

# install rasm z80 assembler
ARG RASM_VERSION=2.3.5
WORKDIR /tmp
ADD https://github.com/EdouardBERGE/rasm/archive/refs/tags/v${RASM_VERSION}.tar.gz .
RUN tar -xf v${RASM_VERSION}.tar.gz
RUN cd rasm-${RASM_VERSION} && make
RUN mv rasm-${RASM_VERSION}/rasm.exe /usr/local/bin/rasm
RUN rm v${RASM_VERSION}.tar.gz && rm -rf ./rasm-${RASM_VERSION}

# install disark disassembler
ARG DISARK_VERSION=1.0.0
WORKDIR /tmp
ADD https://bitbucket.org/JulienNevo/disark/downloads/Disark-linux64-${DISARK_VERSION}.zip .
RUN unzip Disark-linux64-${DISARK_VERSION}.zip
RUN mv disark /usr/local/bin/disark
RUN rm Disark-linux64-${DISARK_VERSION}.zip
