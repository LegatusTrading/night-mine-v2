# System Architecture

This document describes the design and components of Midnight Miner v2.

---

## Design Principles

1. **Simplicity**: Plain bash scripts over complex build systems
2. **Unification**: Same commands work locally and remotely
3. **Safety**: Auto-backup on stop, mnemonic backed up immediately
4. **Transparency**: Solution tracking shows exactly which wallets mined NIGHT

---

## Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                          ./mine                              │
│                    (Main Wrapper Script)                     │
│                                                              │
│  Parses commands: setup, start, stop, watch, status, backup │
│  Routes to lib/*.sh scripts based on operation              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ├──> lib/common.sh (shared functions)
                              │
        ┌─────────────────────┼─────────────────────┬───────────────┐
        │                     │                     │               │
        ▼                     ▼                     ▼               ▼
   lib/setup.sh         lib/start.sh         lib/stop.sh     lib/backup.sh
   lib/watch.sh         lib/status.sh
```

---

## Main Wrapper: `./mine`

**Purpose**: Single entry point for all operations

**Responsibilities**:
- Parse command to extract operation and host
- Load configuration for target host
- Route to appropriate lib/*.sh script

**Command Pattern Parsing**:
```bash
./mine setup           → operation=setup, host=local
./mine setup-s1        → operation=setup, host=s1
./mine status-all      → operation=status, host=all
```

**Flow**:
1. Extract operation and host from command
2. Validate operation
3. Load config via `lib/common.sh:load_config()`
4. Execute corresponding lib script

---

## Shared Functions: `lib/common.sh`

**Purpose**: Provide common utilities used by all operation scripts

### Key Functions

#### `load_config(host)`
Loads configuration from `config/{host}.conf`

**Behavior**:
- For "all": Loads list of all remote server configs into `HOSTS` array
- For specific host: Sources config file, validates required variables
- Exports variables for use in operation scripts

**Validated Variables**:
- `WORKERS`: Number of mining workers
- `WALLETS`: Number of wallets
- `NETWORK`: mainnet or testnet
- `DATA_DIR`: Local backup directory
- `SSH_HOST`: (remote only) SSH connection string
- `REMOTE_DIR`: (remote only) Remote working directory

#### `exec_cmd(cmd)`
Execute command locally or remotely

**Logic**:
```bash
if [ "$HOST" = "local" ]; then
    bash -c "$cmd"
else
    ssh "$SSH_HOST" "cd $REMOTE_DIR && $cmd"
fi
```

#### `is_running()`
Check if miner is running

**Local**: Checks if PID in `.miner.pid` is alive
**Remote**: Checks if systemd service is active

#### `count_solutions()`
Count total solutions from logs

**Local**: `grep -c "Solution accepted" miner.log`
**Remote**: `journalctl -u midnight-miner | grep -c "Solution accepted"`

#### `get_logs(lines)`
Retrieve recent log lines

**Local**: `tail -n $lines miner.log`
**Remote**: `journalctl -u midnight-miner -n $lines`

---

## Operation Scripts

### `lib/setup.sh`

**Purpose**: Prepare mining environment from scratch

**Steps**:
1. **Deploy** (remote only): rsync code to remote server
2. **Install dependencies**: Create Python venv, install requirements
3. **Download tools**: Cardano-address, cardano-cli (if needed)
4. **Generate HD wallet**: Create master seed and derive accounts
5. **Import wallets**: Convert HD wallet to miner format with base addresses
6. **Create systemd service** (remote only): Configure auto-restart service
7. **Backup mnemonic**: Immediately save to `data/{host}/initial-backup/`

**Execution**:
- Local: Run commands directly in project directory
- Remote: Deploy code first, then run commands via SSH

**Safety**:
- Won't overwrite existing HD wallet (warns user)
- Backs up mnemonic immediately after generation
- Shows mnemonic to user for manual recording

---

### `lib/start.sh`

**Purpose**: Start mining process

**Steps**:
1. Check if already running (exit if yes)
2. Start miner:
   - Local: `nohup python3 miner.py --workers N --wallets N > miner.log 2>&1 &`
   - Remote: `systemctl start midnight-miner`
3. Wait 3 seconds for startup
4. Show initial status and recent output

**Process Management**:
- **Local**: Background process with nohup, PID tracked in `.miner.pid`
- **Remote**: systemd service with auto-restart

---

### `lib/stop.sh`

**Purpose**: Stop mining and automatically backup

**Steps**:
1. Check if running (warn if not)
2. Stop miner:
   - Local: Kill process by PID, remove PID file
   - Remote: `systemctl stop midnight-miner`
3. Count final solutions
4. **Automatically call `lib/backup.sh`**

**Safety**: Graceful shutdown (SIGTERM) with fallback to force kill (SIGKILL)

---

### `lib/backup.sh`

**Purpose**: Create timestamped backup with solution report

**Steps**:
1. Create timestamped backup directory: `data/{host}/backup-YYYYMMDD-HHMMSS/`
2. Copy/download files:
   - mnemonic.txt
   - wallets.json
   - challenges.json, balances.json
   - miner.log (local) or journalctl output (remote)
3. Generate REPORT.txt:
   - Parse wallets.json for addresses
   - Parse logs to count solutions per wallet
   - Show which wallets have solutions with timestamps
   - Include recovery instructions
4. Create symlink: `data/{host}/latest` → most recent backup

**Report Generation**:
Uses Python to parse wallets.json and logs:
```python
for wallet in wallets:
    address = wallet["address"]
    solution_count = log.count(f"{address}: Solution accepted")
    # Extract timestamps, show first/last solution
```

---

### `lib/watch.sh`

**Purpose**: Stream live mining output

**Implementation**:
- Local: `tail -f miner.log`
- Remote: `ssh $SSH_HOST "journalctl -u midnight-miner -f"`

**Filtering**: Shows lines containing: Solution, Worker, Challenge, Error, Warning

---

### `lib/status.sh`

**Purpose**: Show current mining status

**Single Host**:
- Running state (✓ or ✗)
- Wallet count
- Total solutions
- Recent solutions (last 5)
- Recent activity (last 5 log lines)

**All Hosts** (`status-all`):
- Iterate through all configured servers
- Show status for each
- Calculate total solutions across all servers

---

## Data Flow

### Setup Flow

```
User: ./mine setup
  ↓
mine script: load_config("local")
  ↓
lib/setup.sh:
  ├─> Install Python venv
  ├─> Download Cardano tools
  ├─> generate-hd-wallet.sh → creates hd-wallets/
  ├─> import-hd-wallets.py → creates wallets.json
  └─> Backup mnemonic → data/local/initial-backup/
```

### Mining Flow

```
User: ./mine start
  ↓
lib/start.sh:
  └─> nohup python3 miner.py --workers 8 --wallets 8 &
        ↓
      miner.py:
        ├─> Load wallets.json
        ├─> Spawn 8 worker processes
        └─> Each worker:
              ├─> Fetch challenge from API
              ├─> Mine (compute hashes)
              ├─> Submit solution to API
              └─> Log: "addr1q...: Solution accepted"
```

### Backup Flow

```
User: ./mine stop
  ↓
lib/stop.sh:
  ├─> Kill miner process
  ├─> Count solutions
  └─> Call lib/backup.sh
        ↓
      lib/backup.sh:
        ├─> Copy/download files
        ├─> Parse logs → count solutions per wallet
        ├─> Generate REPORT.txt
        └─> Create "latest" symlink
```

---

## Remote vs Local Execution

### Differences

| Aspect | Local | Remote |
|--------|-------|--------|
| **Process** | nohup + PID file | systemd service |
| **Logs** | miner.log | journalctl |
| **Deployment** | N/A | rsync code first |
| **Commands** | Direct execution | Via SSH |
| **Backups** | Copy locally | Download via scp |

### Unified via `exec_cmd()`

All operation scripts use `exec_cmd()` which abstracts local vs remote:

```bash
# In any lib/*.sh script:
exec_cmd "python3 miner.py --workers 8 --wallets 8"

# Becomes:
# Local:  bash -c "python3 miner.py --workers 8 --wallets 8"
# Remote: ssh root@HOST "cd /root/miner && python3 miner.py --workers 8 --wallets 8"
```

---

## Configuration System

### Config File Structure

```bash
# config/s1.conf
WORKERS=8              # Passed to miner.py
WALLETS=8              # Used in setup (HD wallet generation)
NETWORK=mainnet        # Passed to generate-hd-wallet.sh
DATA_DIR=/Users/...    # LOCAL path (even for remote!)
SSH_HOST=root@IP       # (remote only)
REMOTE_DIR=/root/miner # (remote only)
```

### Loading Flow

1. `./mine setup-s1` → host = "s1"
2. `load_config("s1")` → sources `config/s1.conf`
3. Variables exported to environment
4. Operation scripts access via `$WORKERS`, `$SSH_HOST`, etc.

### "All" Hosts

For `./mine status-all`, `backup-all`, etc.:

1. `load_config("all")`
2. Scans `config/*.conf` (excluding local.conf)
3. Populates `HOSTS` array: `("s1" "s2" "s3")`
4. Operation script loops through `HOSTS`:
   ```bash
   for host in "${HOSTS[@]}"; do
       load_config "$host"
       # Perform operation
   done
   ```

---

## HD Wallet Integration

### Generation: `generate-hd-wallet.sh`

**From**: Cardano standard tools
**Purpose**: Create HD wallet following BIP39/CIP-1852

**Output**:
```
hd-wallets/
├── mnemonic.txt                    # 24 words
├── root.prv                        # Root extended private key
└── account-{N}/
    ├── payment/0/
    │   ├── payment.skey            # Payment signing key
    │   └── payment.pub             # Payment public key
    └── stake/
        ├── stake.skey              # Stake signing key
        └── stake.pub               # Stake public key
```

### Import: `import-hd-wallets.py`

**Purpose**: Convert HD wallet format to miner format with **base addresses**

**Process**:
```python
for account_num in range(num_wallets):
    # Load both keys
    payment_skey = load(f"account-{account_num}/payment/0/payment.skey")
    stake_skey = load(f"account-{account_num}/stake/stake.skey")

    # Derive public keys
    payment_vkey = payment_skey.to_verification_key()
    stake_vkey = stake_skey.to_verification_key()

    # Create BASE address (not enterprise!)
    address = Address(
        payment_part=payment_vkey.hash(),
        staking_part=stake_vkey.hash(),  # Include stake!
        network=Network.MAINNET
    )

    # Sign terms & conditions
    signature = sign_terms_and_conditions(payment_skey)

    # Save to wallets.json
    wallets.append({
        "address": str(address),  # addr1q... (base address)
        "pubkey": payment_vkey.to_cbor().hex(),
        "signature": signature
    })
```

**Key Point**: Including `staking_part` creates **base address** (addr1q...) instead of **enterprise address** (addr1v...)

---

## Mining Process

### `miner.py` Architecture

```
Main Process
  │
  ├─> Load wallets.json
  ├─> Spawn N worker processes (multiprocessing.Pool)
  └─> Each worker:
        ├─> Assigned one wallet
        ├─> Loop:
        │     ├─> Fetch challenge from API
        │     ├─> Mine (Ashmaize PoW)
        │     ├─> If solution found:
        │     │     └─> Submit to API → log "Solution accepted"
        │     └─> Repeat
        └─> On interrupt: graceful shutdown
```

### Challenge/Solution API

**Endpoint**: `scavenger.prod.gd.midnighttge.io`

**Challenge Fetch**: GET challenge ID and target
**Solution Submit**: POST wallet address, signature, nonce, hash

---

## Backup System

### Why Solution Tracking Matters

Users need to know **which wallets have NIGHT** to recover correctly in Eternl.

### Parsing Strategy

1. **Extract wallet addresses** from wallets.json
2. **Search logs** for each address
3. **Count matches**: `grep -c "addr1q...: Solution accepted"`
4. **Extract timestamps**: Parse log lines for datetime

### Report Structure

```
========================================
WALLET DETAILS
========================================

Wallet 0: addr1qyk9mx...
  Solutions: 0

Wallet 2: addr1qyncsq...
  Solutions: 1
  First solution: 2025-11-15 10:23:45
  Last solution: 2025-11-15 10:23:45

Wallet 5: addr1v98jgs...
  Solutions: 2
  First solution: 2025-11-15 11:15:22
  Last solution: 2025-11-15 12:48:33
```

**User Action**: Switch to Account 2 and Account 5 in Eternl to access NIGHT

---

## Security Considerations

### Mnemonic Protection

- **Generated once** during setup
- **Backed up immediately** to data/{host}/initial-backup/
- **Included in every backup**
- **Shown to user** during setup (for manual recording)

### SSH Keys

- Uses existing SSH keys (no password prompts)
- Assumes `root` access or equivalent
- No credentials stored in configs

### File Permissions

- Scripts executable (755)
- Configs readable (644)
- HD wallet directory (700)
- Mnemonic file (600)

---

## Error Handling

### Common Patterns

**Check before act**:
```bash
if ! is_running; then
    warn "Not running"
    exit 0
fi
```

**Graceful failures**:
```bash
cp wallets.json backup/ 2>/dev/null || warn "No wallets.json found"
```

**Validation**:
```bash
if [ -z "$WORKERS" ]; then
    error "WORKERS not set in config"
fi
```

---

## Extension Points

### Adding New Operations

1. Create `lib/newop.sh`
2. Add to `mine` script:
   ```bash
   case "$OPERATION" in
       setup|start|stop|watch|status|backup|newop)
           ;;
   ```
3. Add case handler:
   ```bash
   case "$OPERATION" in
       newop)
           lib/newop.sh "$HOST"
           ;;
   ```

### Adding New Config Variables

1. Add to config examples
2. Export in `lib/common.sh:load_config()`
3. Use in operation scripts

### Supporting New Platforms

- Detect OS in `lib/setup.sh`
- Download appropriate Cardano tools
- Adjust paths if needed

---

## Performance Considerations

### Why Bash Scripts?

- **Simplicity**: Easy to read, modify, debug
- **Portability**: Works on any Unix-like system
- **No compilation**: Instant execution
- **SSH-friendly**: Easy to execute remotely

### Parallelization

- Mining workers run in parallel (Python multiprocessing)
- SSH operations are sequential (not a bottleneck for management)
- Backup generation is fast (local file operations + simple parsing)

---

## Future Improvements

### Potential Enhancements

1. **Parallel SSH**: Use GNU parallel for bulk operations
2. **Web UI**: Dashboard showing all servers
3. **Metrics**: Track solutions/hour, success rate
4. **Alerts**: Notify when miner stops or solution found
5. **Cloud integration**: Auto-deploy to cloud providers

### Backward Compatibility

All improvements should maintain command compatibility:
```bash
./mine setup      # Must always work
./mine start      # Must always work
# etc.
```

---

## Summary

Midnight Miner v2 architecture is based on:
- **Simple bash scripts** for operations
- **Config-driven execution** for flexibility
- **Unified interface** for consistency
- **HD wallet + base addresses** for recovery
- **Auto-backup with solution tracking** for safety

All components work together to provide a simple, reliable mining system that works identically on local and remote machines.
