#!/bin/bash
# Start mining (local or remote)

set -e

HOST="$1"

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

info "Starting Midnight Miner on $HOST..."

# Check if already running
if is_running; then
    warn "Miner is already running on $HOST"
    exit 0
fi

if [ "$HOST" = "local" ]; then
    # Local: start with nohup
    cd "$SCRIPT_DIR"

    info "Starting local miner with $WORKERS workers, $WALLETS wallets..."

    nohup .venv/bin/python3 miner.py --workers "$WORKERS" --wallets "$WALLETS" > miner.log 2>&1 &
    echo $! > .miner.pid

    success "Miner started (PID: $(cat .miner.pid))"

else
    # Remote: start systemd service
    info "Starting miner on $SSH_HOST..."

    exec_cmd "systemctl start midnight-miner"

    success "Miner service started on $HOST"
fi

# Wait a moment for startup
sleep 3

# Show initial status
info "Checking status..."
echo ""

if [ "$HOST" = "local" ]; then
    if is_running; then
        success "Miner is running"
        echo ""
        info "Recent output:"
        tail -n 10 "$SCRIPT_DIR/miner.log" 2>/dev/null || echo "No output yet"
    else
        error "Miner failed to start. Check miner.log for details."
    fi
else
    if is_running; then
        success "Miner is running on $HOST"
        echo ""
        info "Recent output:"
        exec_cmd "journalctl -u midnight-miner -n 10 --no-pager"
    else
        error "Miner failed to start on $HOST. Check logs with: ./mine watch-$HOST"
    fi
fi

echo ""
info "Monitor with: ./mine watch-$HOST"
info "Check status: ./mine status-$HOST"
