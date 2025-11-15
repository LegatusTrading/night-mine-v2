# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Midnight Miner v2 is a cryptocurrency mining system for Midnight Network's testnet phase. It features a unified command interface (`./mine`) that works identically for local and remote (VPS) mining operations, with HD wallet support and comprehensive backup functionality.

## Development Commands

### Setup and Dependencies

```bash
# Install Python dependencies
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### Running the Miner

```bash
# Local mining
./mine setup              # One-time setup (generates HD wallet, installs deps)
./mine start              # Start mining locally
./mine stop               # Stop mining and auto-backup
./mine status             # Check mining status
./mine watch              # Watch live mining output
./mine backup             # Manual backup with solution report

# Remote mining (requires config/s1.conf)
./mine setup-s1           # Setup remote server
./mine start-s1           # Start mining on remote server
./mine stop-s1            # Stop and download backup
./mine status-s1          # Check remote status
./mine watch-s1           # Watch remote logs

# Multi-server operations
./mine status-all         # Status of all configured servers
./mine backup-all         # Backup all servers
./mine stop-all           # Stop all servers
```

### Configuration

- `config/local.conf` - Local mining configuration
- `config/s*.conf` - Remote server configurations (s1, s2, s3, etc.)
- Each config specifies: WORKERS, WALLETS, NETWORK, DATA_DIR, SSH_HOST (remote only), REMOTE_DIR (remote only)

## Architecture

### Core Components

**`./mine` (Main Wrapper)**
- Entry point that parses commands and delegates to lib/ scripts
- Pattern: `./mine <operation>` (local) or `./mine <operation>-<host>` (remote)
- Extracts operation and host, loads appropriate config, executes lib/ script

**`lib/common.sh`**
- Shared functions used by all operation scripts
- `load_config()` - Loads and validates config files
- `exec_cmd()` - Executes commands locally or via SSH
- `is_running()` - Checks if miner is running (PID file local, systemd remote)
- `count_solutions()` - Parses logs to count accepted solutions

**`lib/setup.sh`**
- Installs Python dependencies in venv
- Downloads Cardano tools (cardano-address, cardano-cli) if missing
- Generates HD wallet using `generate-hd-wallet.sh`
- Imports HD wallets to miner format using `import-hd-wallets.py`
- Creates initial backup with mnemonic

**`lib/start.sh`**
- Checks if already running (error if yes)
- Starts miner: `nohup python3 miner.py --workers N --wallets N > miner.log 2>&1 &` (local)
- Starts miner: `systemctl start midnight-miner` (remote via systemd service)
- Stores PID in `.miner.pid` (local only)

**`lib/stop.sh`**
- Stops mining process (kill PID locally, systemctl stop remotely)
- Counts solutions from logs
- Automatically triggers backup

**`lib/backup.sh`**
- Copies critical files to timestamped backup directory
- Generates REPORT.txt with solution summary (which wallets have NIGHT)
- Downloads backup to local DATA_DIR (remote only)
- Creates symlink to latest backup

**`lib/watch.sh`**
- Tails logs: `tail -f miner.log` (local) or `journalctl -f -u midnight-miner` (remote)

**`lib/status.sh`**
- Shows running state, wallet count, total solutions
- Lists recent solutions from logs

### Python Scripts

**`miner.py`**
- Core mining engine implementing Ashmaize proof-of-work algorithm
- Multi-process mining with worker pool (one wallet per worker)
- Fetches challenges from Midnight Network API
- Submits solutions when found
- Includes 5% donation mechanism to developer pool

**`import-hd-wallets.py`**
- Converts HD wallet structure from `hd-wallets/` to miner-compatible `wallets.json`
- Derives base addresses (addr1q...) compatible with Eternl/Nufi wallets
- Each wallet entry contains: address, payment_vkey, payment_skey, stake_vkey, stake_skey

**`generate-hd-wallet.sh`**
- Creates master 24-word mnemonic using BIP39
- Derives accounts using BIP32/CIP-1852 paths: `m/1852'/1815'/N'`
- Generates payment and stake keys for each account
- Outputs to `hd-wallets/` directory with mnemonic.txt and account-N subdirectories

**`proxy_config.py`**
- HTTP session configuration with optional proxy support
- Used by miner.py for API requests

### HD Wallet Structure

The system uses hierarchical deterministic (HD) wallets following CIP-1852 (Cardano derivation paths):

```
Master Seed (24 words in hd-wallets/mnemonic.txt)
  └─ m/1852'/1815'/0'  → Account 0 → addr1q... (Wallet 0)
  └─ m/1852'/1815'/1'  → Account 1 → addr1q... (Wallet 1)
  └─ m/1852'/1815'/N'  → Account N → addr1q... (Wallet N)
```

**Key Benefits:**
- One mnemonic backs up all wallets
- Compatible with Eternl/Nufi wallets (import once, see all accounts)
- Base addresses (addr1q...) work with standard Cardano wallets and sm.midnight.gd
- Can derive infinite additional wallets from same seed

### Process Management

**Local:**
- Uses nohup + PID file pattern
- PID stored in `.miner.pid`
- Logs to `miner.log`
- Stop via `kill $PID`

**Remote:**
- Uses systemd service: `/etc/systemd/system/midnight-miner.service`
- Start/stop via `systemctl start/stop midnight-miner`
- Logs via `journalctl -u midnight-miner`

### Backup System

**Auto-backup triggers:**
- Every `./mine stop` operation
- After counting solutions from logs

**Backup contents:**
- `mnemonic.txt` - 24-word seed (CRITICAL - recovers all wallets)
- `wallets.json` - All wallet addresses and keys
- `challenges.json`, `balances.json` - Mining state
- `miner.log` - Complete logs
- `REPORT.txt` - Solution summary (which wallet addresses found NIGHT)

**Backup location:** `data/<host>/backup-YYYYMMDD-HHMMSS/`
- Symlink `data/<host>/latest` points to most recent backup

**REPORT.txt format:**
Lists each wallet with solution count and timestamps:
```
Wallet 2: addr1qyncsq...
  Solutions: 1
  First solution: 2025-11-15 10:23:45
  Last solution: 2025-11-15 10:23:45
```

This tells you which account numbers in Eternl wallet contain NIGHT rewards.

## Important Development Notes

### Security - Mnemonic Protection
- The 24-word mnemonic in `hd-wallets/mnemonic.txt` controls ALL wallets
- NEVER commit mnemonic.txt or wallets.json to git
- `.gitignore` should include: `hd-wallets/`, `wallets.json`, `*.log`, `data/`, `.venv/`

### Address Types
- **Base addresses (addr1q...)**: Payment + stake keys, compatible with wallets - THIS IS WHAT WE USE
- **Enterprise addresses (addr1v...)**: Payment only, NOT compatible with Eternl/Nufi - DO NOT USE

### Multi-Server Pattern
- Each server has its own config file: `config/s1.conf`, `config/s2.conf`, etc.
- Each server generates its own unique HD wallet (different mnemonic)
- `-all` suffix operates on all configured servers in parallel

### Local vs Remote Execution
- `exec_cmd()` in lib/common.sh abstracts local vs remote execution
- Local: `bash -c "$cmd"`
- Remote: `ssh $SSH_HOST "cd $REMOTE_DIR && $cmd"`
- All operation scripts use `exec_cmd()` for portability

### Dependencies
- Python 3.8+
- Python packages: pycardano, wasmtime, requests, cbor2, portalocker, mnemonic
- Cardano tools: cardano-address, cardano-cli (auto-downloaded to `tools/`)
- Native Rust library: ashmaize_py (loaded via ashmaize_loader)

### File Locations
- **Generated during mining**: `.venv/`, `hd-wallets/`, `wallets.json`, `challenges.json`, `balances.json`, `miner.log`, `.miner.pid`
- **User data**: `data/<host>/` (backups)
- **Auto-downloaded**: `tools/` (Cardano binaries)

## Common Workflows

### Adding a New Operation
1. Create `lib/new-operation.sh`
2. Source `lib/common.sh` at top
3. Load config with `load_config "$HOST"`
4. Use `exec_cmd()` for all commands
5. Add operation to case statement in `./mine` wrapper

### Testing Local Before Remote
1. Create `config/local.conf`
2. Run `./mine setup` locally
3. Test `./mine start`, `./mine status`, `./mine stop`
4. Verify backup in `data/local/latest/`
5. Then configure remote server with `config/s1.conf`

### Recovery Testing
1. Get mnemonic: `cat data/local/latest/mnemonic.txt`
2. Import to Eternl wallet (Restore → 24 words)
3. Switch between accounts (Account 0, 1, 2...) to see all wallets
4. Account N in Eternl corresponds to Wallet N in miner
5. Check REPORT.txt to see which accounts have solutions

### Debugging
- Local logs: `cat miner.log` or `./mine watch`
- Remote logs: `./mine watch-s1` or `ssh root@host journalctl -u midnight-miner`
- Check if running: `./mine status` (local) or `./mine status-s1` (remote)
- Count solutions: `grep -c "Solution accepted" miner.log`
