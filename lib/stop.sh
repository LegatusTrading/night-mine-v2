#!/bin/bash
# Stop mining and auto-backup (local or remote)

set -e

HOST="$1"

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

info "Stopping Midnight Miner on $HOST..."

# Check if running
if ! is_running; then
    warn "Miner is not running on $HOST"
else
    # Stop the miner
    if [ "$HOST" = "local" ]; then
        # Local: kill by PID
        if [ -f "$SCRIPT_DIR/.miner.pid" ]; then
            local pid=$(cat "$SCRIPT_DIR/.miner.pid")
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid"
                sleep 2

                # Force kill if still running
                if kill -0 "$pid" 2>/dev/null; then
                    warn "Process didn't stop gracefully, forcing..."
                    kill -9 "$pid" 2>/dev/null || true
                fi
            fi
            rm -f "$SCRIPT_DIR/.miner.pid"
        fi

        success "Miner stopped"
    else
        # Remote: stop systemd service
        exec_cmd "systemctl stop midnight-miner"

        success "Miner stopped on $HOST"
    fi
fi

# Get final solution count
info "Counting solutions..."
solutions=$(count_solutions)
success "Total solutions found: $solutions"

# Automatically run backup
echo ""
info "Running automatic backup..."
"$SCRIPT_DIR/lib/backup.sh" "$HOST"

echo ""
success "Miner stopped and backed up successfully!"
