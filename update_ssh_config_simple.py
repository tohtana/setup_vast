#!/usr/bin/env python3
"""
Update SSH config for vast.ai instance (simple version)
Usage: python3 update_ssh_config_simple.py <host> <port> <user> [config_file]
"""

import sys
import os
import re
from pathlib import Path

def update_ssh_config(hostname, port, user, config_file=None):
    """Update SSH config with vast host information"""
    if config_file:
        config_path = Path(config_file).expanduser()
    else:
        config_path = Path.home() / '.ssh' / 'config'
    
    # Ensure .ssh directory exists
    config_path.parent.mkdir(mode=0o700, exist_ok=True)
    
    # Create config file if it doesn't exist
    if not config_path.exists():
        config_path.touch(mode=0o600)
        print(f"Created new SSH config file: {config_path}")
    
    # Read existing config
    try:
        with open(config_path, 'r') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading SSH config: {e}")
        content = ""
    
    # Parse existing vast entry to preserve settings
    existing_settings = {}
    vast_match = re.search(r'Host vast\n((?:[ \t]+.*\n)*)', content, re.MULTILINE)
    if vast_match:
        print("Found existing 'vast' entry, preserving custom settings")
        settings_text = vast_match.group(1)
        # Parse each setting line
        for line in settings_text.split('\n'):
            line = line.strip()
            if line and ' ' in line:
                key, value = line.split(None, 1)
                # Only preserve settings we're not updating
                if key not in ['HostName', 'Port', 'User']:
                    existing_settings[key] = value
    
    # Remove existing vast entry
    content = re.sub(r'Host vast\n(?:[ \t]+.*\n)*', '', content)
    
    # Build new entry
    new_entry = f"Host vast\n"
    new_entry += f"    HostName {hostname}\n"
    new_entry += f"    Port {port}\n"
    new_entry += f"    User {user}\n"
    
    # Add preserved settings
    for key, value in existing_settings.items():
        new_entry += f"    {key} {value}\n"
    
    # Add defaults if not already present
    if 'StrictHostKeyChecking' not in existing_settings:
        new_entry += "    StrictHostKeyChecking no\n"
    if 'UserKnownHostsFile' not in existing_settings:
        new_entry += "    UserKnownHostsFile /dev/null\n"
    
    # Append new entry to config
    content = content.rstrip() + "\n\n" + new_entry
    
    # Write updated config
    try:
        with open(config_path, 'w') as f:
            f.write(content)
        print(f"SSH config updated successfully!")
        print(f"  Host: vast")
        print(f"  HostName: {hostname}")
        print(f"  Port: {port}")
        print(f"  User: {user}")
        return True
    except Exception as e:
        print(f"Error writing SSH config: {e}")
        return False

def main():
    if len(sys.argv) < 4 or len(sys.argv) > 5:
        print("Usage: python3 update_ssh_config_simple.py <host> <port> <user> [config_file]")
        print("  config_file: Optional path to SSH config file (default: ~/.ssh/config)")
        sys.exit(1)
    
    host = sys.argv[1]
    port = sys.argv[2]
    user = sys.argv[3]
    config_file = sys.argv[4] if len(sys.argv) == 5 else None
    
    try:
        if update_ssh_config(host, port, user, config_file):
            print("\nYou can now connect using: ssh vast")
        else:
            sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()