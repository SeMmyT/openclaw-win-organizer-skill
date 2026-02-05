#!/bin/bash
# Fix klow-* scripts by adding required command symlinks
# Run with: sudo bash fix-commands.sh [username]

AGENT_USER="${1:-agent}"
AGENT_BIN="/home/$AGENT_USER/bin"

if [ ! -d "$AGENT_BIN" ]; then
    echo "ERROR: $AGENT_BIN does not exist"
    echo "Usage: sudo bash fix-commands.sh [username]"
    exit 1
fi

# Commands needed by the klow-* scripts
COMMANDS=(
    cat date ls tree head tail wc grep find
    mkdir mv cp rm touch
    basename dirname realpath
    echo printf test
    stat file tee
    sort uniq cut tr sed awk
    shutdown
)

echo "Adding command symlinks to $AGENT_BIN..."

for cmd in "${COMMANDS[@]}"; do
    src=$(which "$cmd" 2>/dev/null)
    if [ -n "$src" ]; then
        ln -sf "$src" "$AGENT_BIN/$cmd"
        echo "  + $cmd -> $src"
    else
        echo "  - $cmd not found"
    fi
done

chown -R "$AGENT_USER:$AGENT_USER" "$AGENT_BIN"

echo ""
echo "Done! Command symlinks created."
