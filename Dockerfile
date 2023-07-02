FROM rust:1.68.0 as Build

RUN apt-get update && apt-get install -y \
    clang\
    cmake \
    curl \
    fuse \
    git \
    libfuse-dev \
    pkg-config \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && git clone --recurse-submodules https://github.com/awslabs/mountpoint-s3.git \
 && cd mountpoint-s3 \
 && cargo build --release

FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libfuse-dev \
    sudo \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /mountpoint-s3/target/release/mount-s3 /usr/local/bin/mount-s3

RUN chmod 777 /usr/local/bin/mount-s3

# RUN useradd -ms /bin/bash mount-s3-user \
#  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
#  && adduser mount-s3-user sudo
# USER mount-s3-user

USER root

RUN mkdir /root/.aws/

## Entry Point
ADD start-script.sh /start-script.sh
RUN chmod 755 /start-script.sh
CMD ["/start-script.sh"]