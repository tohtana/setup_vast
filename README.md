# Vast.ai Setup Scripts

Automated setup scripts for deep learning development environments on Vast.ai GPU instances.

## Quick Start

1. Copy `.env.example` to `.env` and add your tokens:
   ```bash
   cp .env.example .env
   # Edit .env with your GitHub and Hugging Face tokens
   ```

2. Run the automated setup:
   ```bash
   ./auto_setup.sh <instance_id> [username]
   ```
   Example:
   ```bash
   ./auto_setup.sh 23588421 mtanaka
   ```

## Scripts

- **auto_setup.sh** - Main automation script that runs both setup scripts remotely
- **setup.sh** - System-level setup (packages, user creation, SSH)
- **setup_user.sh** - User environment setup (Python packages, git config, DeepSpeed)
- **copy_key.sh** - Helper to copy SSH keys to the "vast" host
- **update_ssh_config_simple.py** - Updates SSH config with instance connection info

## Requirements

- Vast.ai CLI installed (`pip install vastai`)
- Python 3
- SSH access to local machine
- GitHub token with repo access
- Hugging Face token (optional)

## Features

- Automatically updates SSH config for easy connection (`ssh vast`)
- Preserves existing SSH config settings
- Installs ML/DL packages (PyTorch, Transformers, DeepSpeed, etc.)
- Configures tmux and shell aliases
- Sets up development environment for deep learning

## Security Notes

- Store tokens in `.env` file (not committed to git)
- User gets sudo access without password
- SSH StrictHostKeyChecking disabled for Vast.ai instances