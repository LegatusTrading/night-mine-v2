#!/bin/bash
# Setup mining environment (local or remote)

set -e

HOST="$1"

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

info "Setting up Midnight Miner on $HOST..."

# For remote hosts, deploy code first
if [ "$HOST" != "local" ]; then
    info "Deploying code to $SSH_HOST:$REMOTE_DIR..."

    # Create remote directory
    ssh "$SSH_HOST" "mkdir -p $REMOTE_DIR"

    # Copy essential files
    rsync -av --exclude='.git' \
              --exclude='data/' \
              --exclude='__pycache__' \
              --exclude='.venv' \
              --exclude='*.log' \
              --exclude='.miner.pid' \
              "$SCRIPT_DIR/" "$SSH_HOST:$REMOTE_DIR/"

    success "Code deployed to $SSH_HOST"
fi

# Detect OS and architecture
info "Detecting system..."
exec_cmd "uname -s -m"

# Install Python dependencies
info "Installing Python dependencies..."
exec_cmd "
    if [ ! -d .venv ]; then
        python3 -m venv .venv
    fi
    .venv/bin/pip install --upgrade pip
    .venv/bin/pip install -r requirements.txt
"

# Download Cardano tools if needed
info "Checking Cardano tools..."
exec_cmd "
    if [ ! -f tools/cardano-address ]; then
        echo 'Downloading Cardano tools...'
        mkdir -p tools

        # Detect OS for tool download
        OS=\$(uname -s | tr '[:upper:]' '[:lower:]')
        ARCH=\$(uname -m)

        if [ \"\$OS\" = \"darwin\" ]; then
            PLATFORM=\"macos\"
        elif [ \"\$OS\" = \"linux\" ]; then
            PLATFORM=\"linux\"
        else
            echo \"Unsupported OS: \$OS\"
            exit 1
        fi

        # Download cardano-address (example - adjust URLs as needed)
        # This is a placeholder - you'll need actual download URLs
        echo 'Note: Please manually download cardano-address and cardano-cli to tools/ directory'
        echo 'Or install via package manager'
    else
        echo 'Cardano tools found'
    fi
"

# Generate HD wallet
info "Generating HD wallet with $WALLETS accounts..."

if [ "$HOST" = "local" ]; then
    # Local: check if wallet already exists
    if [ -f "$SCRIPT_DIR/hd-wallets/mnemonic.txt" ]; then
        warn "HD wallet already exists. Skipping generation."
        warn "To regenerate, delete hd-wallets/ directory first."
    else
        cd "$SCRIPT_DIR"
        ./generate-hd-wallet.sh --network "$NETWORK" --accounts "$WALLETS" --addresses 1 --output ./hd-wallets
        success "HD wallet generated"
    fi
else
    # Remote: check via SSH
    wallet_exists=$(ssh "$SSH_HOST" "[ -f $REMOTE_DIR/hd-wallets/mnemonic.txt ] && echo 'yes' || echo 'no'")

    if [ "$wallet_exists" = "yes" ]; then
        warn "HD wallet already exists on $HOST. Skipping generation."
    else
        exec_cmd "./generate-hd-wallet.sh --network $NETWORK --accounts $WALLETS --addresses 1 --output ./hd-wallets"
        success "HD wallet generated on $HOST"
    fi
fi

# Import wallets
info "Importing HD wallets to miner format..."
exec_cmd ".venv/bin/python3 ./import-hd-wallets.py ./hd-wallets $WALLETS"
success "Wallets imported"

# For remote: create systemd service
if [ "$HOST" != "local" ]; then
    info "Creating systemd service..."

    ssh "$SSH_HOST" "cat > /etc/systemd/system/midnight-miner.service" <<EOF
[Unit]
Description=Midnight Miner
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$REMOTE_DIR
ExecStart=$REMOTE_DIR/.venv/bin/python3 $REMOTE_DIR/miner.py --workers $WORKERS --wallets $WALLETS
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    ssh "$SSH_HOST" "systemctl daemon-reload"
    success "Systemd service created"
fi

# Backup mnemonic immediately
info "Backing up mnemonic..."

if [ "$HOST" = "local" ]; then
    mkdir -p "$DATA_DIR/$HOST/initial-backup"
    cp "$SCRIPT_DIR/hd-wallets/mnemonic.txt" "$DATA_DIR/$HOST/initial-backup/"
    cp "$SCRIPT_DIR/wallets.json" "$DATA_DIR/$HOST/initial-backup/" 2>/dev/null || true

    success "Initial backup saved to: $DATA_DIR/$HOST/initial-backup/"
    warn "CRITICAL: Save the mnemonic securely!"
    echo ""
    cat "$SCRIPT_DIR/hd-wallets/mnemonic.txt"
    echo ""
else
    mkdir -p "$DATA_DIR/$HOST/initial-backup"
    scp "$SSH_HOST:$REMOTE_DIR/hd-wallets/mnemonic.txt" "$DATA_DIR/$HOST/initial-backup/"
    scp "$SSH_HOST:$REMOTE_DIR/wallets.json" "$DATA_DIR/$HOST/initial-backup/" 2>/dev/null || true

    success "Initial backup downloaded to: $DATA_DIR/$HOST/initial-backup/"
    warn "CRITICAL: Save the mnemonic securely!"
    echo ""
    cat "$DATA_DIR/$HOST/initial-backup/mnemonic.txt"
    echo ""
fi

success "Setup complete for $HOST!"
echo ""
info "Next steps:"
echo "  ./mine start-$HOST    # Start mining"
echo "  ./mine watch-$HOST    # Watch output"
echo "  ./mine status-$HOST   # Check status"
