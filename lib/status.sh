#!/bin/bash
# Show mining status

set -e

HOST="$1"

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Handle "all" hosts
if [ "$HOST" = "all" ]; then
    info "Status for all configured servers:"
    echo ""

    TOTAL_SOLUTIONS=0

    for host in "${HOSTS[@]}"; do
        # Load config for this host
        load_config "$host"

        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Host: $host ($SSH_HOST)"

        # Check if running
        if is_running; then
            success "Status: RUNNING ✓"
        else
            warn "Status: STOPPED ✗"
        fi

        # Count solutions
        solutions=$(count_solutions)
        echo "Solutions: $solutions"

        TOTAL_SOLUTIONS=$((TOTAL_SOLUTIONS + solutions))

        echo ""
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    success "Total solutions across all servers: $TOTAL_SOLUTIONS"
    echo ""

    exit 0
fi

# Single host status
info "Status for $HOST:"
echo ""

# Running status
if is_running; then
    success "Status: RUNNING ✓"

    if [ "$HOST" = "local" ]; then
        pid=$(cat "$SCRIPT_DIR/.miner.pid" 2>/dev/null || echo "unknown")
        echo "PID: $pid"
    fi
else
    warn "Status: STOPPED ✗"
fi

# Wallet count
if [ "$HOST" = "local" ]; then
    if [ -f "$SCRIPT_DIR/wallets.json" ]; then
        wallet_count=$(python3 -c "import json; print(len(json.load(open('$SCRIPT_DIR/wallets.json'))))" 2>/dev/null || echo "unknown")
        echo "Wallets: $wallet_count"
    fi
else
    wallet_count=$(exec_cmd "python3 -c \"import json; print(len(json.load(open('wallets.json'))))\" 2>/dev/null || echo 'unknown'")
    echo "Wallets: $wallet_count"
fi

# Solution count
solutions=$(count_solutions)
success "Total solutions: $solutions"

# Recent solutions
echo ""
info "Recent solutions (last 5):"

if [ "$HOST" = "local" ]; then
    if [ -f "$SCRIPT_DIR/miner.log" ]; then
        grep "Solution accepted" "$SCRIPT_DIR/miner.log" | tail -n 5 || echo "No solutions found"
    else
        echo "No log file"
    fi
else
    exec_cmd "journalctl -u midnight-miner --no-pager | grep 'Solution accepted' | tail -n 5 || echo 'No solutions found'"
fi

# Show uptime if running
echo ""
if is_running; then
    info "Recent activity:"
    get_logs 5
fi
