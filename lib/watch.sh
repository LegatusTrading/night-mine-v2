#!/bin/bash
# Watch live mining output (filtered for important events)

set -e

HOST="$1"

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

info "Watching important events on $HOST (Ctrl+C to exit)..."
info "Filtering: Solutions, Errors, Worker changes, Challenges"
echo ""

if [ "$HOST" = "local" ]; then
    # Local: tail miner.log with filtering
    if [ ! -f "$SCRIPT_DIR/miner.log" ]; then
        warn "No log file yet. Waiting for output..."
        touch "$SCRIPT_DIR/miner.log"
    fi

    # Filter out dashboard spam, show only important events
    tail -f "$SCRIPT_DIR/miner.log" | \
        grep --line-buffered -v "^Active Workers:\|^ID   Address\|^------\|^======\|^\[3J\|^\[H\|^\[2J\|^\[1m\|^\[36m\|^Total Hash Rate:\|^Total Completed:\|^Total NIGHT\|^\*Night balance\|^Press Ctrl" | \
        grep --line-buffered -E "Solution|Worker.*exited|Worker.*started|respawning|Challenge|ERROR|Warning|Exception|Traceback|ImportError|Fetching|MIDNIGHT MINER|Configuration:|Workers:|Wallets|STARTING" || \
        tail -f "$SCRIPT_DIR/miner.log"

else
    # Remote: follow journalctl with filtering
    ssh "$SSH_HOST" "journalctl -u midnight-miner -f --no-pager" | \
        grep --line-buffered -E "(Solution|Worker|Challenge|Error|Warning|Started|Stopped|Exception|Traceback|ImportError)" || \
        ssh "$SSH_HOST" "journalctl -u midnight-miner -f --no-pager"
fi
