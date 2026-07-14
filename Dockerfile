FROM debian:trixie-slim

RUN apt-get update && apt-get install -y \
    nodejs npm openssh-server curl git \
    build-essential \
    pkg-config \
    ca-certificates \
    unzip \
    vim \
    tmux \
    docker.io \
    docker-compose \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash claude && \
    mkdir -p /home/claude/.ssh /opt/npm-global /opt/uv /opt/rustup /opt/cargo && \
    chmod 700 /home/claude/.ssh && \
    chown -R claude:claude /home/claude /opt/npm-global /opt/uv /opt/rustup /opt/cargo

ARG SSH_PUBLIC_KEY
RUN echo "$SSH_PUBLIC_KEY" > /etc/claude-authorized-keys

USER claude

RUN npm config set prefix /opt/npm-global && \
    npm install -g @anthropic-ai/claude-code

ENV UV_INSTALL_DIR="/opt/uv/bin"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

ENV RUSTUP_HOME="/opt/rustup"
ENV CARGO_HOME="/opt/cargo"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

USER root

RUN chown -R claude:claude /opt/uv /opt/rustup /opt/cargo

RUN echo 'export UV_INSTALL_DIR="/opt/uv/bin"' > /etc/profile.d/npmglobal.sh && \
    echo 'export RUSTUP_HOME="/opt/rustup"' >> /etc/profile.d/npmglobal.sh && \
    echo 'export CARGO_HOME="/opt/cargo"' >> /etc/profile.d/npmglobal.sh && \
    echo 'export PATH="/opt/npm-global/bin:/opt/uv/bin:/opt/cargo/bin:$PATH"' >> /etc/profile.d/npmglobal.sh && \
    cat /etc/profile.d/npmglobal.sh >> /home/claude/.bashrc && \
    chown claude:claude /home/claude/.bashrc

RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 22

CMD ["/entrypoint.sh"]