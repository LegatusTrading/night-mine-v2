# Midnight Miner v2

A clean, simple, production-ready mining system for Midnight Network's testnet mining phase. Features unified local/remote operations, HD wallet support, and comprehensive backup with solution tracking.

**Quick Start:** See [QUICKSTART.md](QUICKSTART.md) for ready-to-run examples.

---

## Overview

Midnight Miner v2 is a complete rewrite focused on simplicity and reliability. It provides a single command interface (`./mine`) for all mining operations, whether running locally or on remote VPS servers.

### Key Features

- **Unified Interface**: Same commands work locally and remotely
- **HD Wallet Support**: One 24-word seed controls all wallets (Eternl/Nufi compatible)
- **Base Address**: Compatible with standard Cardano wallets and sm.midnight.gd
- **Auto-Backup**: Every stop triggers comprehensive backup with solution report
- **Config-Driven**: One config file per machine
- **Solution Tracking**: Know exactly which wallets mined NIGHT
- **Multi-Server**: Manage multiple VPS servers from one command

---

## Repository Layout

```
night-mine-v2/
├── mine                      # Main command wrapper
├── lib/                      # Implementation scripts
│   ├── common.sh            # Shared functions (config loading, SSH execution)
│   ├── setup.sh             # Setup environment, generate wallets
│   ├── start.sh             # Start mining
│   ├── stop.sh              # Stop mining (auto-backup)
│   ├── backup.sh            # Backup wallets and generate report
│   ├── watch.sh             # Watch live mining output
│   └── status.sh            # Show mining status
├── config/                   # Configuration files
│   ├── local.conf.example   # Local mining config template
│   ├── s1.conf.example      # Remote server config template
│   └── README.md            # Config documentation
├── data/                     # Backup storage (local)
│   ├── local/               # Local mining backups
│   ├── s1/                  # Server 1 backups (downloaded)
│   └── s2/                  # Server 2 backups (downloaded)
├── doc/                      # Detailed documentation
│   ├── architecture.md      # System design and components
│   ├── hd-wallets.md        # HD wallet structure explained
│   ├── operations.md        # Mining operations guide
│   └── recovery.md          # Wallet recovery procedures
├── tools/                    # Cardano tools (auto-downloaded)
│   ├── cardano-address      # Address derivation tool
│   └── cardano-cli          # Cardano command-line interface
├── miner.py                  # Core mining engine
├── import-hd-wallets.py      # HD wallet importer (base addresses)
├── generate-hd-wallet.sh     # HD wallet generator
├── requirements.txt          # Python dependencies
├── proxy_config.py           # Proxy configuration
├── QUICKSTART.md             # Quick start guide with examples
└── README.md                 # This file
```

### Generated During Mining

```
night-mine-v2/
├── .venv/                    # Python virtual environment
├── hd-wallets/               # HD wallet keys and mnemonic
│   ├── mnemonic.txt         # 24-word seed phrase (CRITICAL!)
│   ├── root.prv             # Root private key
│   └── account-*/           # Derived accounts (wallets)
├── wallets.json              # Wallet addresses for miner
├── challenges.json           # Mining challenges
├── balances.json             # NIGHT balances
├── miner.log                 # Local mining logs
└── .miner.pid                # Local mining process ID
```

---

## How to Trigger Commands

### Command Pattern

```bash
./mine <operation>           # Local
./mine <operation>-<host>    # Remote
./mine <operation>-all       # All configured servers
```

### Available Operations

- **setup**: Install dependencies, generate HD wallet, import wallets
- **start**: Start mining
- **stop**: Stop mining (auto-backup)
- **watch**: Watch live output (Ctrl+C to exit)
- **status**: Show current status
- **backup**: Manual backup with solution report
- **help**: Show help message

### Examples

```bash
# Local
./mine setup              # Setup local environment
./mine start              # Start local mining
./mine watch              # Watch local output
./mine status             # Check local status
./mine stop               # Stop and backup

# Remote (server s1)
./mine setup-s1           # Setup server s1
./mine start-s1           # Start mining on s1
./mine watch-s1           # Watch s1 output
./mine status-s1          # Check s1 status
./mine stop-s1            # Stop s1 and download backup

# All servers
./mine status-all         # Status for all configured servers
./mine backup-all         # Backup all servers
./mine stop-all           # Stop all and backup
```

---

## Configuration

Each machine (local or remote) has its own config file in `config/`.

### Local Configuration: `config/local.conf`

```bash
# Number of mining workers (CPU cores)
WORKERS=8

# Number of wallets to create
WALLETS=8

# Network (mainnet or testnet)
NETWORK=mainnet

# Local data directory for backups
DATA_DIR=/Users/yourname/mining/data
```

### Remote Configuration: `config/s1.conf`

```bash
# Number of mining workers
WORKERS=8

# Number of wallets
WALLETS=8

# Network
NETWORK=mainnet

# Local data directory (on YOUR machine, not remote!)
DATA_DIR=/Users/yourname/mining/data

# SSH connection
SSH_HOST=root@51.159.135.76

# Remote directory where miner runs
REMOTE_DIR=/root/miner
```

### Important: DATA_DIR is Always Local

Even for remote mining, `DATA_DIR` points to your local machine. Backups are automatically downloaded from remote servers to your local `DATA_DIR`.

---

## HD Wallet Structure

### One Seed, Many Wallets

Each machine gets one 24-word mnemonic that derives all its wallets:

```
Master Seed (24 words in hd-wallets/mnemonic.txt)
  └─ m/1852'/1815'/0'  → Account 0 → addr1q... (Wallet 0)
  └─ m/1852'/1815'/1'  → Account 1 → addr1q... (Wallet 1)
  └─ m/1852'/1815'/2'  → Account 2 → addr1q... (Wallet 2)
  └─ m/1852'/1815'/N'  → Account N → addr1q... (Wallet N)
```

### Benefits

- **One Backup**: 24 words recover all wallets
- **Eternl Compatible**: Import once, see all accounts
- **Base Addresses**: Works with standard Cardano wallets
- **Infinite Accounts**: Can derive more wallets from same seed

### How Setup Works

1. **Generate HD Wallet**: Creates master seed and derives N accounts
   ```bash
   ./generate-hd-wallet.sh --network mainnet --accounts 8 --output hd-wallets
   ```

2. **Import to Miner**: Converts HD wallet to miner format with base addresses
   ```bash
   python3 import-hd-wallets.py ./hd-wallets 8
   ```

3. **Backup Immediately**: Mnemonic backed up to `data/HOST/initial-backup/`

---

## Mining Operations

### Local Mining

**Process Management**: nohup + PID file
- Starts: `nohup python3 miner.py --workers 8 --wallets 8 > miner.log 2>&1 &`
- Tracks: PID stored in `.miner.pid`
- Logs: Output written to `miner.log`

**Stopping**: Kills process by PID, removes PID file

### Remote Mining

**Process Management**: systemd service
- Service: `/etc/systemd/system/midnight-miner.service`
- Starts: `systemctl start midnight-miner`
- Logs: `journalctl -u midnight-miner`

**Stopping**: `systemctl stop midnight-miner`

### Execution Flow

1. **Setup** → Deploys code (remote) → Installs deps → Generates wallet → Imports → Backups mnemonic
2. **Start** → Checks if running → Starts miner → Waits 3s → Shows status
3. **Watch** → Tails logs (local: miner.log, remote: journalctl)
4. **Status** → Shows running state → Counts solutions → Lists recent
5. **Stop** → Stops miner → Counts solutions → **Auto-backup**
6. **Backup** → Copies files → Generates solution report → Downloads (remote)

---

## Backup and Recovery

### What Gets Backed Up

Every backup includes:
- `mnemonic.txt`: Your 24-word seed (CRITICAL!)
- `wallets.json`: All wallet addresses and keys
- `challenges.json`: Mining challenge data
- `balances.json`: NIGHT balances
- `miner.log`: Complete mining logs
- `REPORT.txt`: Solution summary (which wallets have NIGHT)

### Backup Location

```
data/
└── <host>/
    ├── initial-backup/           # Created during setup
    ├── backup-20251115-143022/   # Timestamped backups
    ├── backup-20251115-180945/
    └── latest -> backup-20251115-180945/  # Symlink to latest
```

### Solution Report

Each backup includes `REPORT.txt` showing:
- Total wallets and solutions
- Which wallets found solutions (with timestamps)
- Recovery instructions
- Files included in backup

Example:
```
Wallet 2: addr1qyncsq9wxulhwqae2n68a57yqj7zetlcx9yhptadrjpnw...
  Solutions: 1
  First solution: 2025-11-15 10:23:45
  Last solution: 2025-11-15 10:23:45

Wallet 5: addr1v98jgsalz4qyye0exx5ntqtwqus5tt7rkuxayhnpr5ng7...
  Solutions: 2
  First solution: 2025-11-15 11:15:22
  Last solution: 2025-11-15 12:48:33
```

### Recovery Process

1. **Get mnemonic** from backup: `cat data/s1/latest/mnemonic.txt`
2. **Import to Eternl**:
   - Restore wallet
   - Enter 24 words
   - Eternl shows all accounts
3. **Access rewards**:
   - Switch to accounts that have solutions (from REPORT.txt)
   - Check balances on sm.midnight.gd

See [QUICKSTART.md Example 5](QUICKSTART.md#example-5-restoring-in-eternlnufi-wallet) for step-by-step guide.

---

## Multiple Server Management

### Setup

1. Create config for each server:
   ```bash
   cp config/s1.conf.example config/s1.conf  # Edit for server 1
   cp config/s1.conf.example config/s2.conf  # Edit for server 2
   cp config/s1.conf.example config/s3.conf  # Edit for server 3
   ```

2. Setup all servers:
   ```bash
   ./mine setup-s1
   ./mine setup-s2
   ./mine setup-s3
   ```

3. Start all:
   ```bash
   ./mine start-s1
   ./mine start-s2
   ./mine start-s3
   ```

### Bulk Operations

```bash
# Check all servers at once
./mine status-all

# Output:
# Host: s1 (51.159.135.76)
# Status: RUNNING ✓
# Solutions: 12
#
# Host: s2 (51.159.135.77)
# Status: RUNNING ✓
# Solutions: 15
#
# Total solutions: 27

# Backup all servers
./mine backup-all

# Stop all servers (stops + backups)
./mine stop-all
```

---

## Technical Details

### Address Types

**Base Addresses (addr1q...)**:
- Payment key + Stake key
- Compatible with Eternl, Nufi, Daedalus
- Accepted by sm.midnight.gd
- **This is what we use**

**Enterprise Addresses (addr1v...)**:
- Payment key only (no staking)
- NOT compatible with most wallets
- NOT accepted by sm.midnight.gd
- **We do NOT use these**

### Mining Algorithm

- **Proof of Work**: Ashmaize algorithm
- **Challenge System**: Fetch challenges from API
- **Multi-Worker**: Each worker mines with one wallet
- **Solution Submission**: POST to scavenger.prod.gd.midnighttge.io

### Dependencies

- **Python**: 3.8+
- **Libraries**: pycardano, requests, etc. (see requirements.txt)
- **Cardano Tools**: cardano-address, cardano-cli
- **Remote**: SSH access with root (or sudo)

---

## Security

### Critical: Protect Your Mnemonic

- **24 words = Complete control** of all wallets
- **Backup securely**: Password manager, offline storage, etc.
- **Never share**: Anyone with mnemonic can take your NIGHT
- **Multiple backups**: Initial backup + every stop/backup

### Best Practices

1. **Backup immediately** after setup
2. **Regular backups**: Use `./mine backup` or auto on `./mine stop`
3. **Secure storage**: Encrypt backups, use strong passwords
4. **Offline copy**: Write mnemonic on paper, store safely
5. **Test recovery**: Import mnemonic to Eternl to verify it works

---

## Troubleshooting

### Miner Won't Start

```bash
# Check logs
./mine watch             # Local
./mine watch-s1          # Remote

# Common issues:
# - Python dependencies not installed (run ./mine setup)
# - Wallet file missing (run ./mine setup)
# - Port already in use (check if already running)
```

### SSH Connection Failed

```bash
# Test connection
ssh root@51.159.135.76

# Check config
cat config/s1.conf
# Verify SSH_HOST is correct

# Check SSH keys
ssh-add -l  # List loaded keys
```

### No Solutions

- **This is normal!** Mining is probabilistic
- Solutions are rare and random
- Keep mining and monitoring
- Check `./mine status` regularly

### Lost Mnemonic

```bash
# Check backups
cat data/local/latest/mnemonic.txt
cat data/local/initial-backup/mnemonic.txt
cat data/s1/latest/mnemonic.txt

# If all backups lost: NO RECOVERY POSSIBLE
# This is why multiple backups are critical!
```

---

## Development

### Project Origin

This is a clean rewrite of the original midnight-miner project, focusing on:
- Simplicity (simple bash scripts vs 580-line Makefile)
- Completeness (backup with solution reports)
- Base addresses (Eternl/sm.midnight.gd compatibility)
- Unified interface (same commands everywhere)

### Branches

- **baseaddr**: HD wallet with base addresses (this version)
- **enterpriseaddr**: Old version with enterprise addresses (deprecated)
- **main**: Same as enterpriseaddr (deprecated)

### Contributing

For improvements or bug fixes:
1. Test locally first
2. Test on remote VPS
3. Update documentation
4. Ensure backward compatibility

---

## Resources

- **Documentation**: See [doc/](doc/) folder for detailed guides
- **Quick Start**: [QUICKSTART.md](QUICKSTART.md) with ready-to-run examples
- **Config Help**: [config/README.md](config/README.md)
- **Midnight Network**: Official testnet information
- **sm.midnight.gd**: Solution verification and balance checking

---

## License

[Your license here]

---

## Support

For issues or questions:
- Check [QUICKSTART.md](QUICKSTART.md) for common examples
- Review [doc/](doc/) for detailed documentation
- Check backup REPORT.txt for solution tracking
- Test mnemonic import in Eternl to verify recovery works

**Mining ends in days - act fast!**
