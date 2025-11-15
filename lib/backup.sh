#!/bin/bash
# Backup wallets and mining data

set -e

HOST="$1"

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

info "Creating backup for $HOST..."

# Create timestamped backup directory
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR_NAME="backup-$TIMESTAMP"
LOCAL_BACKUP_PATH="$DATA_DIR/$HOST/$BACKUP_DIR_NAME"

mkdir -p "$LOCAL_BACKUP_PATH"

if [ "$HOST" = "local" ]; then
    # Local backup
    info "Backing up local files..."

    # Copy critical files
    cp "$SCRIPT_DIR/hd-wallets/mnemonic.txt" "$LOCAL_BACKUP_PATH/" 2>/dev/null || warn "No mnemonic found"
    cp "$SCRIPT_DIR/wallets.json" "$LOCAL_BACKUP_PATH/" 2>/dev/null || warn "No wallets.json found"
    cp "$SCRIPT_DIR/challenges.json" "$LOCAL_BACKUP_PATH/" 2>/dev/null || true
    cp "$SCRIPT_DIR/balances.json" "$LOCAL_BACKUP_PATH/" 2>/dev/null || true
    cp "$SCRIPT_DIR/miner.log" "$LOCAL_BACKUP_PATH/" 2>/dev/null || true

    SOURCE_DIR="$SCRIPT_DIR"

else
    # Remote backup - download files
    info "Downloading files from $SSH_HOST..."

    # Create temporary directory on remote
    exec_cmd "mkdir -p /tmp/$BACKUP_DIR_NAME"

    # Copy files on remote to temp directory
    exec_cmd "
        cp hd-wallets/mnemonic.txt /tmp/$BACKUP_DIR_NAME/ 2>/dev/null || echo 'No mnemonic'
        cp wallets.json /tmp/$BACKUP_DIR_NAME/ 2>/dev/null || echo 'No wallets.json'
        cp challenges.json /tmp/$BACKUP_DIR_NAME/ 2>/dev/null || true
        cp balances.json /tmp/$BACKUP_DIR_NAME/ 2>/dev/null || true
    "

    # Download logs
    ssh "$SSH_HOST" "journalctl -u midnight-miner --no-pager > /tmp/$BACKUP_DIR_NAME/miner.log"

    # Download all files
    scp -r "$SSH_HOST:/tmp/$BACKUP_DIR_NAME/*" "$LOCAL_BACKUP_PATH/" 2>/dev/null || true

    # Cleanup remote temp
    exec_cmd "rm -rf /tmp/$BACKUP_DIR_NAME"

    SOURCE_DIR="$LOCAL_BACKUP_PATH"
fi

# Generate solution report
info "Generating solution report..."

REPORT_FILE="$LOCAL_BACKUP_PATH/REPORT.txt"

# Read wallets.json to get wallet addresses
if [ -f "$LOCAL_BACKUP_PATH/wallets.json" ]; then
    WALLETS_JSON="$LOCAL_BACKUP_PATH/wallets.json"
elif [ -f "$SOURCE_DIR/wallets.json" ]; then
    WALLETS_JSON="$SOURCE_DIR/wallets.json"
else
    WALLETS_JSON=""
fi

# Create report
cat > "$REPORT_FILE" <<EOF
========================================
MIDNIGHT MINER - BACKUP REPORT
========================================
Host: $HOST
Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Backup: $LOCAL_BACKUP_PATH

========================================
SEED PHRASE (CRITICAL)
========================================
EOF

if [ -f "$LOCAL_BACKUP_PATH/mnemonic.txt" ]; then
    cat >> "$REPORT_FILE" <<EOF
Location: mnemonic.txt
Words: $(wc -w < "$LOCAL_BACKUP_PATH/mnemonic.txt" | tr -d ' ')
Backup: ✓ Included in this backup

⚠️  STORE THIS BACKUP SECURELY!
    This seed phrase controls all $WALLETS wallets.

EOF
else
    cat >> "$REPORT_FILE" <<EOF
⚠️  WARNING: No mnemonic.txt found!

EOF
fi

cat >> "$REPORT_FILE" <<EOF
========================================
MINING SUMMARY
========================================
EOF

# Count total solutions
if [ -f "$LOCAL_BACKUP_PATH/miner.log" ]; then
    TOTAL_SOLUTIONS=$(grep -c "Solution accepted" "$LOCAL_BACKUP_PATH/miner.log" 2>/dev/null || echo "0")
else
    TOTAL_SOLUTIONS="0"
fi

cat >> "$REPORT_FILE" <<EOF
Total Wallets: $WALLETS
Total Solutions: $TOTAL_SOLUTIONS

EOF

# Parse solutions per wallet
cat >> "$REPORT_FILE" <<EOF
========================================
WALLET DETAILS
========================================

EOF

if [ -n "$WALLETS_JSON" ] && [ -f "$WALLETS_JSON" ]; then
    # Extract addresses from wallets.json
    python3 <<PYTHON_SCRIPT >> "$REPORT_FILE"
import json
import re

# Load wallets
with open("$WALLETS_JSON") as f:
    wallets = json.load(f)

# Load log file
try:
    with open("$LOCAL_BACKUP_PATH/miner.log") as f:
        log_content = f.read()
except:
    log_content = ""

# Parse solutions per wallet
for i, wallet in enumerate(wallets):
    address = wallet.get("address", "Unknown")

    # Count solutions for this address
    solution_count = log_content.count(f"{address}: Solution accepted")

    print(f"Wallet {i}: {address}")
    print(f"  Solutions: {solution_count}")

    if solution_count > 0:
        # Find solution timestamps
        pattern = rf"(\d{{4}}-\d{{2}}-\d{{2}} \d{{2}}:\d{{2}}:\d{{2}}).*{re.escape(address)}.*Solution accepted"
        matches = re.findall(pattern, log_content)
        if matches:
            print(f"  First solution: {matches[0]}")
            print(f"  Last solution: {matches[-1]}")
    print()

PYTHON_SCRIPT
else
    echo "No wallet information available" >> "$REPORT_FILE"
fi

# Add recovery instructions
cat >> "$REPORT_FILE" <<EOF
========================================
RECOVERY INSTRUCTIONS
========================================

1. Import seed to Eternl/Nufi:
   - Restore wallet with 24-word seed from mnemonic.txt
   - Wallet will show all $WALLETS accounts

2. Check wallets with solutions:
   - See wallet details above
   - Switch between accounts in Eternl to access each wallet
   - Check balances on sm.midnight.gd

3. Total recoverable: $TOTAL_SOLUTIONS solutions

========================================
FILES INCLUDED
========================================
EOF

# List backup contents
for file in "$LOCAL_BACKUP_PATH"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "✓ $filename" >> "$REPORT_FILE"
    fi
done

cat >> "$REPORT_FILE" <<EOF

========================================
EOF

success "Backup created: $LOCAL_BACKUP_PATH"
echo ""
info "Solution report:"
cat "$REPORT_FILE"

# Create symlink to latest backup
rm -f "$DATA_DIR/$HOST/latest"
ln -s "$BACKUP_DIR_NAME" "$DATA_DIR/$HOST/latest"

echo ""
success "Latest backup linked: $DATA_DIR/$HOST/latest"
