#!/bin/bash

# Auto-setup script for Vast.ai instances
# Usage: ./auto_setup.sh <instance_id> [user_name]

set -e

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <instance_id> [user_name]"
    echo "Example: $0 23588421"
    echo "Example: $0 23588421 mtanaka"
    exit 1
fi

INSTANCE_ID=$1
USER_NAME=${2:-mtanaka}  # Default to mtanaka if not specified

# Get SSH connection info from vastai
echo "Getting SSH connection info for instance $INSTANCE_ID..."
SSH_INFO=$(vastai ssh-url "$INSTANCE_ID" 2>/dev/null | tail -1)

if [ -z "$SSH_INFO" ]; then
    echo "Error: Could not get SSH info for instance $INSTANCE_ID"
    echo "Make sure the instance ID is correct and you have access to it."
    exit 1
fi

echo "SSH connection string: $SSH_INFO"

# Extract connection parameters
# Expected format: ssh://user@host:port
if [[ $SSH_INFO =~ ssh://([^@]+)@([^:]+):([0-9]+) ]]; then
    REMOTE_USER="${BASH_REMATCH[1]}"
    HOST="${BASH_REMATCH[2]}"
    PORT="${BASH_REMATCH[3]}"
else
    echo "Error: Could not parse SSH connection info"
    echo "SSH info: $SSH_INFO"
    exit 1
fi

echo "Parsed connection info:"
echo "  Host: $HOST"
echo "  Port: $PORT"
echo "  Remote user: $REMOTE_USER"
echo "  Target user: $USER_NAME"
echo ""

# Update SSH config in both locations
echo "Updating SSH config for host 'vast'..."

# Update primary SSH config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/update_ssh_config_simple.py" "$HOST" "$PORT" "$USER_NAME"

# Also update Windows SSH config if it exists and is different
WINDOWS_SSH_CONFIG="/mnt/c/Users/mtanaka/.ssh/config"
if [ -f "$WINDOWS_SSH_CONFIG" ] && [ "$HOME/.ssh/config" != "$WINDOWS_SSH_CONFIG" ]; then
    echo "Also updating Windows SSH config..."
    python3 "$SCRIPT_DIR/update_ssh_config_simple.py" "$HOST" "$PORT" "$USER_NAME" "$WINDOWS_SSH_CONFIG"
fi

echo ""

# Check if setup scripts exist locally
if [ ! -f "$SCRIPT_DIR/setup.sh" ] || [ ! -f "$SCRIPT_DIR/setup_user.sh" ]; then
    echo "Error: setup.sh and setup_user.sh must be in the same directory as this script"
    exit 1
fi

# Load configuration from .env file if it exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "Loading configuration from .env file..."
    source "$SCRIPT_DIR/.env"
else
    echo "Warning: No .env file found. Create one from .env.example if you need to set tokens."
fi

# Function to run SSH commands
run_ssh() {
    ssh -p "$PORT" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" "$REMOTE_USER@$HOST" "$@"
}

# Function to copy files via SCP
copy_scp() {
    scp -P "$PORT" -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" "$@"
}

echo "Step 1: Copying setup scripts to remote instance..."
copy_scp "$SCRIPT_DIR/setup.sh" "$SCRIPT_DIR/setup_user.sh" "$REMOTE_USER@$HOST:/tmp/"

echo ""
echo "Step 2: Running setup.sh as root..."
echo "This will:"
echo "  - Install system packages"
echo "  - Create user '$USER_NAME' with sudo privileges"
echo "  - Configure SSH access"
echo ""

# Run setup.sh as root, passing the username as an argument
run_ssh "sudo bash /tmp/setup.sh $USER_NAME"

echo ""
echo "Step 3: Copying setup_user.sh to the new user's home directory..."
run_ssh "sudo cp /tmp/setup_user.sh /home/$USER_NAME/ && sudo chown $USER_NAME:$USER_NAME /home/$USER_NAME/setup_user.sh && sudo chmod +x /home/$USER_NAME/setup_user.sh"

echo ""
echo "Step 4: Running setup_user.sh as $USER_NAME..."
echo "This will:"
echo "  - Configure shell environment"
echo "  - Install Python packages"
echo "  - Set up development tools"
echo ""

# Check if GH_DS_TOKEN is available (from .env file or environment)
if [ -z "$GH_DS_TOKEN" ]; then
    echo "WARNING: GH_DS_TOKEN is not set!"
    echo "Please either:"
    echo "  1. Create a .env file from .env.example and add your GitHub token"
    echo "  2. Export it: export GH_DS_TOKEN=your_github_token"
    echo ""
    echo "The DeepSpeed repository clone will fail without it."
    read -p "Do you want to continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "Found GH_DS_TOKEN"
fi

# Run setup_user.sh as the target user with both tokens
ENV_VARS=""
if [ -n "$GH_DS_TOKEN" ]; then
    ENV_VARS="export GH_DS_TOKEN=\"$GH_DS_TOKEN\";"
fi
if [ -n "$HF_TOKEN" ]; then
    ENV_VARS="${ENV_VARS} export HF_TOKEN=\"$HF_TOKEN\";"
fi

run_ssh "sudo -u $USER_NAME bash -c 'cd /home/$USER_NAME && ${ENV_VARS} ./setup_user.sh'"

echo ""
echo "Step 5: Cleaning up temporary files..."
run_ssh "sudo rm -f /tmp/setup.sh /tmp/setup_user.sh"

echo ""
echo "Setup complete!"
echo ""
echo "You can now connect to the instance as $USER_NAME using:"
echo "  ssh -p $PORT $USER_NAME@$HOST"
echo ""
echo "Or connect as the original user:"
echo "  $SSH_INFO"