#!/bin/bash
# Common functions for Midnight Miner

# Color output (optional, for better UX)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Error handling
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
}

info() {
    echo -e "${BLUE}$1${NC}"
}

success() {
    echo -e "${GREEN}$1${NC}"
}

# Show help message
show_help() {
    cat <<EOF
Midnight Miner - Universal Mining Interface

USAGE:
  ./mine <command>               # Local operations
  ./mine <command>-<host>        # Remote operations
  ./mine <command>-all           # All configured servers

COMMANDS:
  setup         Setup mining environment (install deps, generate wallets)
  start         Start mining
  stop          Stop mining (auto-backup)
  watch         Watch live mining output
  status        Show current mining status
  backup        Backup wallets and data
  help          Show this help

EXAMPLES:
  Local mining:
    ./mine setup              # Setup local environment
    ./mine start              # Start local mining
    ./mine watch              # Watch local output
    ./mine status             # Check local status
    ./mine stop               # Stop and backup

  Remote mining (server s1):
    ./mine setup-s1           # Setup s1
    ./mine start-s1           # Start mining on s1
    ./mine watch-s1           # Watch s1 output
    ./mine status-s1          # Check s1 status
    ./mine stop-s1            # Stop s1 and download backup

  All servers:
    ./mine status-all         # Status of all configured servers
    ./mine backup-all         # Backup all servers
    ./mine stop-all           # Stop all servers

CONFIGURATION:
  config/local.conf         # Local mining config
  config/s1.conf           # Server 1 config
  config/s2.conf           # Server 2 config
  ...

See QUICKSTART.md for detailed examples.
EOF
}

# Load configuration
load_config() {
    local host="$1"

    if [ "$host" = "all" ]; then
        # Load all server configs into arrays
        HOSTS=()
        for config_file in "$SCRIPT_DIR"/config/*.conf; do
            if [ -f "$config_file" ]; then
                local hostname=$(basename "$config_file" .conf)
                if [ "$hostname" != "local" ]; then
                    HOSTS+=("$hostname")
                fi
            fi
        done

        if [ ${#HOSTS[@]} -eq 0 ]; then
            error "No remote server configs found in config/"
        fi

        info "Found ${#HOSTS[@]} configured server(s): ${HOSTS[*]}"
        return 0
    fi

    # Load specific host config
    local config_file="$SCRIPT_DIR/config/$host.conf"

    if [ ! -f "$config_file" ]; then
        error "Configuration not found: $config_file"
    fi

    # Source the config file
    # shellcheck source=/dev/null
    source "$config_file"

    # Validate required variables
    if [ -z "$WORKERS" ]; then
        error "WORKERS not set in $config_file"
    fi

    if [ -z "$WALLETS" ]; then
        error "WALLETS not set in $config_file"
    fi

    if [ -z "$NETWORK" ]; then
        error "NETWORK not set in $config_file"
    fi

    if [ -z "$DATA_DIR" ]; then
        error "DATA_DIR not set in $config_file"
    fi

    # For remote hosts, validate SSH_HOST
    if [ "$host" != "local" ] && [ -z "$SSH_HOST" ]; then
        error "SSH_HOST not set in $config_file"
    fi

    # Set defaults
    REMOTE_DIR="${REMOTE_DIR:-/root/miner}"

    # Export for use in sub-scripts
    export WORKERS WALLETS NETWORK DATA_DIR SSH_HOST REMOTE_DIR
    export HOST="$host"
}

# Execute command (local or remote)
exec_cmd() {
    local cmd="$1"

    if [ "$HOST" = "local" ]; then
        # Execute locally
        bash -c "$cmd"
    else
        # Execute remotely via SSH
        if [ -z "$SSH_HOST" ]; then
            error "SSH_HOST not configured for remote execution"
        fi

        ssh "$SSH_HOST" "cd $REMOTE_DIR && $cmd"
    fi
}

# Check if mining is running
is_running() {
    if [ "$HOST" = "local" ]; then
        # Check local PID file
        if [ -f "$SCRIPT_DIR/.miner.pid" ]; then
            local pid=$(cat "$SCRIPT_DIR/.miner.pid")
            if kill -0 "$pid" 2>/dev/null; then
                return 0
            fi
        fi
        return 1
    else
        # Check remote systemd service
        if exec_cmd "systemctl is-active midnight-miner >/dev/null 2>&1"; then
            return 0
        fi
        return 1
    fi
}

# Get mining logs
get_logs() {
    local lines="${1:-50}"

    if [ "$HOST" = "local" ]; then
        if [ -f "$SCRIPT_DIR/miner.log" ]; then
            tail -n "$lines" "$SCRIPT_DIR/miner.log"
        else
            warn "No log file found: miner.log"
        fi
    else
        exec_cmd "journalctl -u midnight-miner -n $lines --no-pager"
    fi
}

# Count solutions from logs
count_solutions() {
    if [ "$HOST" = "local" ]; then
        if [ -f "$SCRIPT_DIR/miner.log" ]; then
            grep -c "Solution accepted" "$SCRIPT_DIR/miner.log" 2>/dev/null || echo "0"
        else
            echo "0"
        fi
    else
        exec_cmd "journalctl -u midnight-miner --no-pager | grep -c 'Solution accepted' || echo 0"
    fi
}
