#!/bin/bash
# Watch live mining output

set -e

HOST="$1"

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

info "Watching miner output on $HOST (Ctrl+C to exit)..."
echo ""

if [ "$HOST" = "local" ]; then
    # Local: tail miner.log
    if [ ! -f "$SCRIPT_DIR/miner.log" ]; then
        warn "No log file yet. Waiting for output..."
        touch "$SCRIPT_DIR/miner.log"
    fi

    tail -f "$SCRIPT_DIR/miner.log" | grep --line-buffered -E "(Solution|Worker|Challenge|Error|Warning|Started|Stopped)" || tail -f "$SCRIPT_DIR/miner.log"

else
    # Remote: follow journalctl
    ssh "$SSH_HOST" "journalctl -u midnight-miner -f --no-pager" | grep --line-buffered -E "(Solution|Worker|Challenge|Error|Warning|Started|Stopped)" || ssh "$SSH_HOST" "journalctl -u midnight-miner -f --no-pager"
fi
