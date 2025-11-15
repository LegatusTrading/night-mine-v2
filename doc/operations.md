# Mining Operations Guide

Complete guide to all mining operations, workflows, and best practices.

---

## Operation Overview

| Operation | Purpose | Auto-Backup | Safe to Run Anytime |
|-----------|---------|-------------|---------------------|
| setup     | Initial environment setup | Yes (initial) | No (changes config) |
| start     | Start mining | No | Yes (checks if running) |
| stop      | Stop mining | Yes (automatic) | Yes (graceful) |
| watch     | View live output | No | Yes (read-only) |
| status    | Check current state | No | Yes (read-only) |
| backup    | Manual backup | Yes | Yes (safe) |

---

## Setup Operation

### Purpose

Prepare a fresh machine for mining from scratch.

### What It Does

1. **Deploy code** (remote only): rsync project to remote server
2. **Install Python**: Create venv, install dependencies
3. **Download tools**: Cardano-address, cardano-cli
4. **Generate HD wallet**: Create master seed, derive accounts
5. **Import wallets**: Convert to miner format with base addresses
6. **Create service** (remote only): systemd service definition
7. **Backup mnemonic**: Save to data/{host}/initial-backup/

### Usage

```bash
# Local
./mine setup

# Remote
./mine setup-s1
```

### Prerequisites

**Local**:
- Python 3.8+
- config/local.conf configured

**Remote**:
- SSH access to server
- Root privileges (or sudo)
- config/s1.conf configured

### Configuration Required

```bash
# In config/local.conf or config/s1.conf
WORKERS=8              # How many CPU cores to use
WALLETS=8              # How many wallets to create
NETWORK=mainnet        # Network type
DATA_DIR=/path/to/data # Where to store backups
SSH_HOST=root@IP       # (remote only)
REMOTE_DIR=/root/miner # (remote only)
```

### Output

**Success**:
```
Setting up Midnight Miner on s1...
Deploying code to root@51.159.135.76:/root/miner...
Code deployed to root@51.159.135.76
Detecting system...
Linux x86_64
Installing Python dependencies...
Successfully installed pycardano requests...
Generating HD wallet with 8 accounts...
HD wallet generated on s1
Importing HD wallets to miner format...
Wallets imported
Creating systemd service...
Systemd service created
Backing up mnemonic...
Initial backup saved to: /Users/yourname/mining/data/s1/initial-backup/
CRITICAL: Save the mnemonic securely!

rare energy visit fire ready surge gate around usage any elegant piano
gaze multiply moment rule guard busy material biology gentle saddle caught knife

Setup complete for s1!

Next steps:
  ./mine start-s1    # Start mining
  ./mine watch-s1    # Watch output
  ./mine status-s1   # Check status
```

### Files Created

**Local**:
```
./
├── .venv/              # Python virtual environment
├── hd-wallets/         # HD wallet keys
│   ├── mnemonic.txt
│   ├── root.prv
│   └── account-*/
├── wallets.json        # Miner wallet format
└── tools/              # Cardano tools

data/local/
└── initial-backup/
    ├── mnemonic.txt
    └── wallets.json
```

**Remote**:
```
/root/miner/                    # Remote directory
├── .venv/
├── hd-wallets/
├── wallets.json
└── ... (all project files)

/etc/systemd/system/
└── midnight-miner.service      # Systemd service

data/s1/                         # Local backup directory
└── initial-backup/
    ├── mnemonic.txt
    └── wallets.json
```

### Important Notes

- **Mnemonic shown to user**: Write it down or save to password manager
- **Won't overwrite existing wallet**: If hd-wallets/ exists, warns user
- **Auto-backup**: Mnemonic immediately backed up to DATA_DIR
- **Systemd service**: Remote servers get auto-restart on crash

### Troubleshooting

**"Configuration not found"**:
- Check config/{host}.conf exists
- Verify all required variables set

**"Python not found"**:
- Install Python 3.8+
- For remote: `ssh root@HOST "apt install python3 python3-venv"`

**"SSH connection failed"**:
- Verify SSH_HOST in config
- Test: `ssh root@HOST`
- Check SSH keys loaded

**"HD wallet already exists"**:
- Intentional safety feature
- To regenerate: `rm -rf hd-wallets/ wallets.json` first
- WARNING: Only do this if you have backup or no solutions yet

---

## Start Operation

### Purpose

Start the mining process.

### What It Does

1. Check if already running (exit if yes)
2. Start miner process:
   - Local: `nohup python3 miner.py ... &`
   - Remote: `systemctl start midnight-miner`
3. Wait 3 seconds for startup
4. Show initial status and output

### Usage

```bash
# Local
./mine start

# Remote
./mine start-s1

# All servers (sequential)
for host in s1 s2 s3; do
    ./mine start-$host
done
```

### Prerequisites

- Setup already run (`./mine setup` or `./mine setup-s1`)
- Not currently running
- wallets.json exists

### Output

**Success (local)**:
```
Starting Midnight Miner on local...
Starting local miner with 8 workers, 8 wallets...
Miner started (PID: 12345)
Checking status...

Miner is running
Recent output:
2025-11-15 14:30:22 - Starting miner with 8 workers
2025-11-15 14:30:22 - Worker 0 started with wallet addr1qyk9mx...
2025-11-15 14:30:22 - Worker 1 started with wallet addr1qxvx84...
...

Monitor with: ./mine watch-local
Check status: ./mine status-local
```

**Already running**:
```
Miner is already running on s1
```

### Process Details

**Local**:
- Command: `nohup python3 miner.py --workers 8 --wallets 8 > miner.log 2>&1 &`
- PID: Saved to `.miner.pid`
- Logs: Written to `miner.log`
- Survives: Terminal close (nohup)
- Restart: Manual (not automatic)

**Remote**:
- Service: `midnight-miner`
- Management: systemd
- Logs: journalctl
- Survives: SSH disconnect, server reboot
- Restart: Automatic on crash

### Monitoring

After starting:
```bash
# Watch live output
./mine watch

# Check status
./mine status

# View specific number of log lines
./mine watch  # Ctrl+C to exit
```

### Troubleshooting

**"Miner failed to start"**:
```bash
# Check logs
./mine watch

# Common causes:
# - wallets.json missing (run ./mine setup)
# - Python dependencies not installed
# - Another instance already running (check ps aux | grep miner.py)
```

**"Port already in use"**:
- Another miner instance running
- Check: `ps aux | grep miner.py`
- Kill: `pkill -f miner.py` (or ./mine stop)

**Silent failure (no output)**:
```bash
# Check Python errors
.venv/bin/python3 miner.py --workers 8 --wallets 8

# Check dependencies
.venv/bin/pip list
```

---

## Stop Operation

### Purpose

Stop mining gracefully and automatically backup.

### What It Does

1. Check if running
2. Stop the miner:
   - Local: Send SIGTERM to PID, wait, SIGKILL if needed
   - Remote: `systemctl stop midnight-miner`
3. Count final solutions
4. **Automatically run backup** (includes solution report)

### Usage

```bash
# Local
./mine stop

# Remote
./mine stop-s1

# All servers
./mine stop-all
```

### Output

```
Stopping Midnight Miner on s1...
Miner stopped on s1
Counting solutions...
Total solutions found: 5

Running automatic backup...
Creating backup for s1...
Downloading files from root@51.159.135.76...
Generating solution report...
Backup created: /Users/yourname/mining/data/s1/backup-20251115-143022

[REPORT.txt contents shown here]

Latest backup linked: /Users/yourname/mining/data/s1/latest

Miner stopped and backed up successfully!
```

### Backup Contents

Every stop creates:
```
data/s1/backup-20251115-143022/
├── mnemonic.txt           # Master seed (24 words)
├── wallets.json           # All wallet addresses
├── challenges.json        # Mining challenge data
├── balances.json          # NIGHT balances
├── miner.log              # Complete mining logs
└── REPORT.txt             # Solution summary
```

### Solution Report

Shows exactly which wallets mined NIGHT:
```
Wallet 2: addr1qyncsq...
  Solutions: 1
  First solution: 2025-11-15 10:23:45
  Last solution: 2025-11-15 10:23:45

Wallet 5: addr1v98jgs...
  Solutions: 2
  First solution: 2025-11-15 11:15:22
  Last solution: 2025-11-15 12:48:33
```

**Use this to know which Eternl accounts have rewards!**

### Important Notes

- **Always creates backup**: Every stop triggers backup
- **Graceful shutdown**: Gives miner time to finish current work
- **Force kill**: If doesn't stop in 2 seconds, uses SIGKILL
- **Solution tracking**: Report shows which wallets to recover

### When to Stop

**Good times**:
- Before server maintenance
- Before upgrading miner code
- To create manual backup
- End of mining period

**Bad times**:
- Don't stop/start repeatedly (wastes time)
- Let it run continuously for best results

---

## Watch Operation

### Purpose

Stream live mining output in real-time.

### What It Does

Tails the mining logs, filtering for important events.

### Usage

```bash
# Local
./mine watch

# Remote
./mine watch-s1

# Exit: Ctrl+C
```

### Output

```
Watching miner output on s1 (Ctrl+C to exit)...

2025-11-15 14:30:22 - Worker 0: Fetching challenge 1105
2025-11-15 14:30:25 - Worker 2: Mining challenge 1105
2025-11-15 14:30:30 - Worker 3: Fetching challenge 1106
2025-11-15 14:31:15 - Worker 5: addr1v98jgs...: Solution accepted for challenge 1105!
2025-11-15 14:31:16 - Worker 5: Fetching challenge 1107
...
```

### Log Filtering

Shows lines containing:
- "Solution" (solution found/accepted)
- "Worker" (worker status)
- "Challenge" (challenge fetch/mining)
- "Error" (errors)
- "Warning" (warnings)

Hides:
- Verbose debug output
- Heartbeat messages
- Routine status updates

### Use Cases

**Monitor for solutions**:
```bash
./mine watch | grep "Solution accepted"
```

**Check for errors**:
```bash
./mine watch | grep -i error
```

**Count solutions live**:
```bash
./mine watch | grep -c "Solution accepted"
```

### Exiting

Press **Ctrl+C** to stop watching (miner keeps running)

---

## Status Operation

### Purpose

Quick snapshot of current mining state.

### What It Does

**Single host**:
- Show running/stopped state
- Count wallets
- Count total solutions
- Show recent solutions (last 5)
- Show recent activity

**All hosts** (`status-all`):
- Iterate through all configured servers
- Show status for each
- Calculate total across all

### Usage

```bash
# Local
./mine status

# Remote
./mine status-s1

# All servers
./mine status-all
```

### Output (Single Host)

```
Status for s1:

Status: RUNNING ✓
Wallets: 8
Total solutions: 5

Recent solutions (last 5):
2025-11-15 14:31:15 - Worker 5: addr1v98jgs...: Solution accepted
2025-11-15 14:28:42 - Worker 5: addr1v98jgs...: Solution accepted
2025-11-15 14:25:10 - Worker 7: addr1v9egju...: Solution accepted
2025-11-15 14:20:33 - Worker 7: addr1v9egju...: Solution accepted
2025-11-15 14:15:45 - Worker 2: addr1qyncsq...: Solution accepted

Recent activity:
2025-11-15 14:35:00 - Worker 3: Fetching challenge 1110
2025-11-15 14:34:58 - Worker 1: Mining challenge 1109
...
```

### Output (All Hosts)

```
Status for all configured servers:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Host: s1 (51.159.135.76)
Status: RUNNING ✓
Solutions: 12

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Host: s2 (51.159.135.77)
Status: RUNNING ✓
Solutions: 15

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Host: s3 (51.159.135.78)
Status: STOPPED ✗
Solutions: 8

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total solutions across all servers: 35
```

### Use Cases

**Quick check**:
```bash
./mine status-all
```

**Monitor specific server**:
```bash
watch -n 10 './mine status-s1'  # Update every 10 seconds
```

**Solution rate calculation**:
```bash
# Check solutions now
./mine status | grep "Total solutions"
# Wait 1 hour
./mine status | grep "Total solutions"
# Calculate: (new - old) solutions/hour
```

---

## Backup Operation

### Purpose

Create manual backup with solution report (separate from stop).

### What It Does

Same as stop's automatic backup, but without stopping:

1. Create timestamped backup directory
2. Copy/download all data files
3. Generate solution report
4. Create "latest" symlink

### Usage

```bash
# Local
./mine backup

# Remote
./mine backup-s1

# All servers
./mine backup-all
```

### When to Use

- **Regular backups**: Daily or weekly
- **Before risky operations**: Code updates, server changes
- **Solution verification**: Check which wallets have NIGHT
- **Peace of mind**: Anytime you want a fresh backup

### Backup Frequency

**Recommended**:
- Daily: `./mine backup-all` (cron job)
- Before stop: Automatic
- After finding solution: Manual

**Example cron**:
```bash
# Backup all servers daily at 3 AM
0 3 * * * cd /path/to/night-mine-v2 && ./mine backup-all
```

### Output

```
Creating backup for s1...
Downloading files from root@51.159.135.76...
Generating solution report...
Backup created: /Users/yourname/mining/data/s1/backup-20251115-180945

[REPORT.txt shown]

Latest backup linked: /Users/yourname/mining/data/s1/latest
```

### Accessing Backups

**Latest backup**:
```bash
cat data/s1/latest/REPORT.txt
```

**Specific backup**:
```bash
cat data/s1/backup-20251115-180945/REPORT.txt
```

**List all backups**:
```bash
ls -lt data/s1/
```

---

## Best Practices

### Initial Setup

1. **Configure first**:
   ```bash
   cp config/local.conf.example config/local.conf
   # Edit with your settings
   ```

2. **Setup environment**:
   ```bash
   ./mine setup
   ```

3. **Backup mnemonic immediately**:
   ```bash
   # Already done automatically
   # But also manually save:
   cp data/local/initial-backup/mnemonic.txt ~/safe-location/
   ```

4. **Test recovery**:
   - Import mnemonic to Eternl
   - Verify Account 0 address matches wallets.json

5. **Start mining**:
   ```bash
   ./mine start
   ```

---

### Daily Operations

**Morning check**:
```bash
./mine status-all
```

**Regular backup** (cron):
```bash
0 3 * * * cd /path/to/night-mine-v2 && ./mine backup-all
```

**Monitor occasionally**:
```bash
./mine watch-s1
# Ctrl+C when done watching
```

---

### Maintenance

**Update miner code**:
```bash
# Stop all
./mine stop-all

# Update code (git pull, etc.)
git pull origin baseaddr

# Restart all
./mine start-s1
./mine start-s2
./mine start-s3
```

**Check for issues**:
```bash
# Watch for errors
./mine watch | grep -i error

# Check if all running
./mine status-all
```

---

### End of Mining Period

```bash
# Stop all (creates final backups)
./mine stop-all

# Verify backups
cat data/s1/latest/REPORT.txt
cat data/s2/latest/REPORT.txt
cat data/s3/latest/REPORT.txt

# Recovery test
# Import each mnemonic to Eternl
# Verify addresses match reports
```

---

## Operational Workflows

### New Server Deployment

```bash
# 1. Create config
cp config/s1.conf.example config/s4.conf
# Edit: SSH_HOST, REMOTE_DIR, DATA_DIR

# 2. Setup
./mine setup-s4

# 3. Verify backup
cat data/s4/initial-backup/mnemonic.txt

# 4. Start
./mine start-s4

# 5. Monitor
./mine watch-s4
# Wait for first challenge fetch, Ctrl+C

# 6. Check status
./mine status-s4
```

**Time**: ~5 minutes per server

---

### Server Migration

Moving from old server to new:

```bash
# 1. Backup old server
ssh old-server "cd /old/path && tar czf backup.tar.gz hd-wallets/ wallets.json"
scp old-server:/old/path/backup.tar.gz ./

# 2. Stop old server
ssh old-server "systemctl stop old-miner"

# 3. Deploy to new server
./mine setup-s_new

# 4. Replace wallet with old
scp backup.tar.gz new-server:/root/miner/
ssh new-server "cd /root/miner && tar xzf backup.tar.gz"

# 5. Start new server
./mine start-s_new
```

---

### Multi-Server Start/Stop

**Start all**:
```bash
for host in s1 s2 s3 s4; do
    echo "Starting $host..."
    ./mine start-$host
    sleep 5  # Give time to stabilize
done
```

**Stop all** (use built-in):
```bash
./mine stop-all
```

**Status all** (use built-in):
```bash
./mine status-all
```

---

## Troubleshooting Workflows

### Miner Crashed

```bash
# 1. Check status
./mine status-s1
# Output: STOPPED ✗

# 2. Check recent logs
./mine watch-s1
# Look for errors before crash

# 3. Backup current state
./mine backup-s1

# 4. Restart
./mine start-s1

# 5. Monitor closely
./mine watch-s1
```

### No Solutions for Hours

```bash
# 1. Check if running
./mine status

# 2. Check for errors
./mine watch | grep -i error

# 3. Check network
ssh root@HOST "ping -c 3 scavenger.prod.gd.midnighttge.io"

# 4. Verify wallet registration
# Check challenges.json, balances.json exist

# 5. Be patient
# Solutions are RARE and RANDOM
# Could be hours or days between solutions
```

### Backup Recovery Test

```bash
# 1. Get mnemonic
cat data/s1/latest/mnemonic.txt

# 2. Import to Eternl
# (Follow Eternl restore process)

# 3. Compare addresses
cat data/s1/latest/wallets.json | jq '.[0].address'
# vs Eternl Account 0 receive address

# 4. Check solutions
cat data/s1/latest/REPORT.txt
# Note which wallets have solutions

# 5. Verify in Eternl
# Switch to those accounts
# See NIGHT balance
```

---

## Summary

### Operation Quick Reference

```bash
./mine setup           # First time setup
./mine start           # Start mining
./mine watch           # Monitor live (Ctrl+C to exit)
./mine status          # Quick check
./mine backup          # Manual backup
./mine stop            # Stop + auto-backup

./mine status-all      # All servers status
./mine backup-all      # All servers backup
./mine stop-all        # All servers stop + backup
```

### Key Principles

1. **Setup once**: Each machine needs setup once
2. **Start/stop freely**: Safe to start/stop anytime
3. **Auto-backup on stop**: Every stop creates backup
4. **Monitor occasionally**: watch and status are safe
5. **Backup regularly**: Manual backups for peace of mind
6. **Check reports**: Solution reports show what to recover

**Simple, safe, reliable mining operations!**
