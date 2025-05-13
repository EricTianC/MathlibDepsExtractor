FROM ubuntu:22.04
LABEL Name=mathlibdepsextractor Version=0.0.1

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    sudo \
    git \
    curl \
    bash-completion \
    python3 \
    python3-requests \
    build-essential \
    libffi-dev \
    libssl-dev \
    pkg-config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash -G sudo leanuser \
    && echo "leanuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER leanuser
WORKDIR /home/leanuser

RUN curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y
ENV PATH="/home/leanuser/.elan/bin:${PATH}"

COPY . /home/leanuser/mathlibdepsextractor
RUN sudo chown -R leanuser:leanuser /home/leanuser/mathlibdepsextractor
WORKDIR /home/leanuser/mathlibdepsextractor
RUN elan toolchain install $(cat lean-toolchain) \
    && elan default $(cat lean-toolchain) \
    && lake --version
RUN lake exe cache get \
    && lake build

CMD [ "bash", "-l" ]
