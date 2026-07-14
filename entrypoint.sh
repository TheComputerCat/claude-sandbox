#!/bin/bash
chown -R claude:claude /home/claude

if [ ! -f /home/claude/.ssh/authorized_keys ]; then
    mkdir -p /home/claude/.ssh
    cp /etc/claude-authorized-keys /home/claude/.ssh/authorized_keys
    chmod 700 /home/claude/.ssh
    chmod 600 /home/claude/.ssh/authorized_keys
    chown -R claude:claude /home/claude/.ssh
fi

if [ ! -f /home/claude/.ssh/host_keys/ssh_host_ed25519_key ]; then
    mkdir -p /home/claude/.ssh/host_keys
    ssh-keygen -A  # generates default host keys to /etc/ssh
    cp /etc/ssh/ssh_host_* /home/claude/.ssh/host_keys/
else
    cp /home/claude/.ssh/host_keys/ssh_host_* /etc/ssh/
fi

if [ -S /var/run/docker.sock ]; then
    DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
    if ! getent group "$DOCKER_GID" > /dev/null; then
        groupadd -g "$DOCKER_GID" docker-host
    fi
    usermod -aG "$DOCKER_GID" claude
fi

exec /usr/sbin/sshd -D