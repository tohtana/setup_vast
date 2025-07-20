export ENV_NAME=gh
export BASE_DIR=${HOME}/work/${ENV_NAME}
mkdir -p ${BASE_DIR}

echo 'export PATH=${HOME}/.local/bin:$PATH' >> ~/.bashrc \
    && echo 'export NCCL_DEBUG=WARN' >> ~/.bashrc \
    && echo "alias ll='ls -alF'" >> ~/.bashrc \
    && echo "alias sa='eval \$(ssh-agent) && ssh-add ${HOME}/.ssh/id_rsa'" >> ~/.bashrc \
    && echo "cd ${BASE_DIR}" >> ~/.bashrc

export PATH=${HOME}/.local/bin:$PATH

# add the following lines to ~/.tmux.conf
cat << EOF > ~/.tmux.conf
set -g prefix C-t
unbind C-b

set -g mouse on

bind-key    -T prefix C-n       next-window
bind-key    -T prefix C-p       previous-window

setw -g mode-keys vi
bind-key -T copy-mode-vi 'f' send-keys -X page-up
bind-key -T copy-mode-vi 'b' send-keys -X page-down

set-option -g history-limit 20000
EOF
 
# Install python3
sudo apt-get update && sudo apt-get install -y python3 python3-pip

# Ensure 'python' points to 'python3'
sudo ln -sf /usr/bin/python3 /usr/bin/python

# Clone DeepSpeed repository with GitHub token

git config --global user.email "tanaka.masahiro@gmail.com" \
    && git config --global user.name "Masahiro Tanaka" \
    && git config --global credential.helper store

pip3 install --user pre-commit clang-format accelerate pytest-xdist pydot nltk \
    torch_tb_profiler datasets lightning wheel transformers wandb huggingface-hub[cli]

# check if HF_TOKEN is set
if [ -z "${HF_TOKEN}" ]; then
    echo "Warning: HF_TOKEN is not set. Skipping Hugging Face login."
else
    huggingface-cli login --token ${HF_TOKEN}
fi

cd /workspace
# check if GH_DS_TOKEN is set
if [ -z "${GH_DS_TOKEN}" ]; then
    echo "Error: GH_DS_TOKEN is not set. Please set it to your GitHub token."
    exit 1
fi
git clone https://${GH_DS_TOKEN}@github.com/deepspeedai/DeepSpeed.git

