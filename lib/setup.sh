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
        # Prefer Python 3.13 or 3.12 (3.14+ incompatible with ashmaize_py.so)
        PYTHON_CMD=python3
        for py in python3.13 python3.12 python3.11 python3.10; do
            if command -v \$py >/dev/null 2>&1; then
                PYTHON_CMD=\$py
                echo \"Using \$py (\$(\$py --version))\"
                break
            fi
        done

        # Check if default python3 is too new (3.14+)
        if [ \"\$PYTHON_CMD\" = \"python3\" ]; then
            PY_VERSION=\$(python3 -c 'import sys; print(f\"{sys.version_info.major}.{sys.version_info.minor}\")')
            if [ \"\$PY_VERSION\" = \"3.14\" ] || [ \"\$PY_VERSION\" = \"3.15\" ]; then
                echo \"WARNING: Python 3.14+ detected. This is incompatible with ashmaize_py.so\"
                echo \"Please install Python 3.13 or 3.12 and try again.\"
                exit 1
            fi
        fi

        \$PYTHON_CMD -m venv .venv
    fi
    .venv/bin/pip install --upgrade pip
    .venv/bin/pip install -r requirements.txt
"

# Download Cardano tools if needed
info "Checking Cardano tools..."
exec_cmd "
    if [ ! -f lib/cardano-address ] || [ ! -f lib/cardano-cli ]; then
        echo 'Downloading Cardano tools...'
        mkdir -p lib

        # Detect OS and architecture
        OS=\$(uname -s | tr '[:upper:]' '[:lower:]')
        ARCH=\$(uname -m)

        # Normalize architecture
        if [ \"\$ARCH\" = \"arm64\" ] || [ \"\$ARCH\" = \"aarch64\" ]; then
            ARCH=\"arm64\"
        elif [ \"\$ARCH\" = \"x86_64\" ] || [ \"\$ARCH\" = \"amd64\" ]; then
            ARCH=\"x64\"
        fi

        # Download cardano-address
        if [ ! -f lib/cardano-address ]; then
            echo 'Downloading cardano-address...'
            CARDANO_ADDR_VERSION=\"4.0.1\"

            if [ \"\$OS\" = \"darwin\" ]; then
                CARDANO_ADDR_URL=\"https://github.com/IntersectMBO/cardano-addresses/releases/download/\${CARDANO_ADDR_VERSION}/cardano-addresses-\${CARDANO_ADDR_VERSION}-darwin.tar.gz\"
            elif [ \"\$OS\" = \"linux\" ]; then
                CARDANO_ADDR_URL=\"https://github.com/IntersectMBO/cardano-addresses/releases/download/\${CARDANO_ADDR_VERSION}/cardano-addresses-\${CARDANO_ADDR_VERSION}-linux.tar.gz\"
            else
                echo \"Unsupported OS: \$OS\"
                exit 1
            fi

            curl -L -o /tmp/cardano-address.tar.gz \"\$CARDANO_ADDR_URL\"
            tar -xzf /tmp/cardano-address.tar.gz -C lib/ bin/cardano-address --strip-components=1
            chmod +x lib/cardano-address
            rm /tmp/cardano-address.tar.gz
            echo '✓ cardano-address downloaded'
        fi

        # Download cardano-cli
        if [ ! -f lib/cardano-cli ]; then
            echo 'Downloading cardano-cli...'
            CARDANO_CLI_VERSION=\"10.1.3.0\"

            if [ \"\$OS\" = \"darwin\" ]; then
                CARDANO_CLI_URL=\"https://github.com/IntersectMBO/cardano-node/releases/download/\${CARDANO_CLI_VERSION}/cardano-node-\${CARDANO_CLI_VERSION}-macos.tar.gz\"
            elif [ \"\$OS\" = \"linux\" ]; then
                CARDANO_CLI_URL=\"https://github.com/IntersectMBO/cardano-node/releases/download/\${CARDANO_CLI_VERSION}/cardano-node-\${CARDANO_CLI_VERSION}-linux.tar.gz\"
            else
                echo \"Unsupported OS: \$OS\"
                exit 1
            fi

            curl -L -o /tmp/cardano-cli.tar.gz \"\$CARDANO_CLI_URL\"
            tar -xzf /tmp/cardano-cli.tar.gz -C lib/ bin/cardano-cli --strip-components=1 2>/dev/null || tar -xzf /tmp/cardano-cli.tar.gz -C lib/ cardano-cli
            chmod +x lib/cardano-cli
            rm /tmp/cardano-cli.tar.gz
            echo '✓ cardano-cli downloaded'
        fi
    else
        echo '✓ Cardano tools already installed'
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
