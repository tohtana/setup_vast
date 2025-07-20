export USER_NAME=mtanaka

apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    git \
    curl \
    vim \
    tmux \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

useradd -s /bin/bash -m ${USER_NAME} \
    && echo "${USER_NAME}:${USER_NAME}" | chpasswd \
    && usermod -aG sudo ${USER_NAME} \
    && echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir -p /home/${USER_NAME}/.ssh

cp ~/.ssh/authorized_keys /home/${USER_NAME}/.ssh/
chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.ssh
chmod 700 /home/${USER_NAME}/.ssh
chmod 600 /home/${USER_NAME}/.ssh/authorized_keys

chmod -R a+w /workspace

