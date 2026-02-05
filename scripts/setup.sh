#!/bin/bash
# OpenClaw Windows Organizer - Setup Script
# Run with: sudo bash setup.sh

set -e

# ============================================
# CONFIGURATION - EDIT THESE VALUES
# ============================================

AGENT_USER="agent"
AGENT_SSH_KEY="ssh-ed25519 YOUR_PUBLIC_KEY_HERE agent@server"
WINDOWS_USER="$USER"  # Will be detected, or set manually
SSH_PORT=2222

# Workspace folders (created on Windows Desktop)
WORKSPACE_NAME="AgentWorkspace"
TRASH_NAME="AgentTrash"

# ============================================
# DO NOT EDIT BELOW THIS LINE
# ============================================

echo "============================================"
echo "  OpenClaw Windows Organizer Setup"
echo "============================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run with sudo"
    exit 1
fi

# Detect Windows username from WSL
if [ -d "/mnt/c/Users" ]; then
    # Try to detect Windows user
    DETECTED_USER=$(ls /mnt/c/Users | grep -v "Public\|Default\|All Users" | head -1)
    if [ -n "$DETECTED_USER" ]; then
        WINDOWS_USER="$DETECTED_USER"
        echo "[*] Detected Windows user: $WINDOWS_USER"
    fi
fi

WINDOWS_DESKTOP="/mnt/c/Users/$WINDOWS_USER/Desktop"
WORKSPACE_PATH="$WINDOWS_DESKTOP/$WORKSPACE_NAME"
TRASH_PATH="$WINDOWS_DESKTOP/$TRASH_NAME"

echo "[*] Windows Desktop: $WINDOWS_DESKTOP"
echo "[*] Workspace: $WORKSPACE_PATH"
echo "[*] Trash: $TRASH_PATH"
echo ""

# ============================================
# 1. Create agent user
# ============================================
echo "[1/7] Creating agent user..."

if id "$AGENT_USER" &>/dev/null; then
    echo "      User $AGENT_USER already exists"
else
    useradd -m -s /bin/rbash "$AGENT_USER"
    echo "      Created user $AGENT_USER with rbash"
fi

# ============================================
# 2. Set up restricted PATH
# ============================================
echo "[2/7] Setting up restricted environment..."

AGENT_HOME="/home/$AGENT_USER"
AGENT_BIN="$AGENT_HOME/bin"

mkdir -p "$AGENT_BIN"
mkdir -p "$AGENT_HOME/logs"

# Create .bashrc that sets restricted PATH
cat > "$AGENT_HOME/.bashrc" << 'BASHRC'
# Restricted shell configuration
export PATH="$HOME/bin"
export PS1="OpenClaw Organizer > "

echo "OpenClaw Windows Organizer - Restricted Shell"
echo "Type 'klow-help' for available commands"
BASHRC

# Lock down profile
cat > "$AGENT_HOME/.profile" << 'PROFILE'
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
PROFILE

chown -R "$AGENT_USER:$AGENT_USER" "$AGENT_HOME"
chmod 755 "$AGENT_HOME"
chmod 700 "$AGENT_BIN"

# ============================================
# 3. Install klow-* commands
# ============================================
echo "[3/7] Installing klow-* commands..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KLOW_SRC="$SCRIPT_DIR/klow-commands"

if [ -d "$KLOW_SRC" ]; then
    cp "$KLOW_SRC"/klow-* "$AGENT_BIN/" 2>/dev/null || true
    cp "$KLOW_SRC"/klow-common.sh "$AGENT_BIN/" 2>/dev/null || true
    cp "$KLOW_SRC"/blocked-paths.txt "$AGENT_BIN/" 2>/dev/null || true
    chmod +x "$AGENT_BIN"/klow-*
    echo "      Installed commands from $KLOW_SRC"
else
    echo "      WARNING: klow-commands directory not found at $KLOW_SRC"
fi

# ============================================
# 4. Add required command symlinks
# ============================================
echo "[4/7] Adding command symlinks for rbash..."

COMMANDS=(cat date ls tree head tail wc grep find mkdir mv cp rm touch basename dirname realpath echo printf test stat file tee sort uniq cut tr sed awk shutdown)

for cmd in "${COMMANDS[@]}"; do
    src=$(which "$cmd" 2>/dev/null)
    if [ -n "$src" ]; then
        ln -sf "$src" "$AGENT_BIN/$cmd"
    fi
done

chown -R "$AGENT_USER:$AGENT_USER" "$AGENT_BIN"

# ============================================
# 5. Set up SSH key
# ============================================
echo "[5/7] Setting up SSH key..."

AGENT_SSH="$AGENT_HOME/.ssh"
mkdir -p "$AGENT_SSH"

echo "$AGENT_SSH_KEY" > "$AGENT_SSH/authorized_keys"

chown -R "$AGENT_USER:$AGENT_USER" "$AGENT_SSH"
chmod 700 "$AGENT_SSH"
chmod 600 "$AGENT_SSH/authorized_keys"

# ============================================
# 6. Configure SSH server
# ============================================
echo "[6/7] Configuring SSH server on port $SSH_PORT..."

# Backup original config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup 2>/dev/null || true

# Set port
if grep -q "^Port " /etc/ssh/sshd_config; then
    sed -i "s/^Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config
else
    echo "Port $SSH_PORT" >> /etc/ssh/sshd_config
fi

# Generate host keys if missing
ssh-keygen -A 2>/dev/null || true

# Start SSH
service ssh start || /usr/sbin/sshd

# ============================================
# 7. Create Windows folders
# ============================================
echo "[7/7] Creating workspace folders..."

mkdir -p "$WORKSPACE_PATH"
mkdir -p "$TRASH_PATH"

# Create welcome file
cat > "$WORKSPACE_PATH/WELCOME.md" << EOF
# Agent Workspace

This folder is managed by your AI assistant.

## What goes here
- Files the agent is organizing
- Work in progress
- Anything the agent needs read/write access to

## Trash folder
Files marked for deletion go to $TRASH_NAME with manifests.
Review and permanently delete when ready.
EOF

echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "SSH listening on port $SSH_PORT"
echo "Agent user: $AGENT_USER"
echo "Workspace: $WORKSPACE_PATH"
echo "Trash: $TRASH_PATH"
echo ""
echo "Next steps:"
echo "1. Set up Windows port forwarding (see windows/ folder)"
echo "2. Configure Windows firewall for Tailscale"
echo "3. Add SKILL.md to your AI agent"
echo ""
echo "Test connection:"
echo "  ssh -p $SSH_PORT $AGENT_USER@<TAILSCALE_IP>"
