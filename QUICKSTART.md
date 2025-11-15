# Midnight Miner - Quick Start Guide

Get mining in 5 minutes! This guide provides ready-to-run examples for local and remote mining.

## Prerequisites

- Python 3.8+
- SSH access to remote servers (for remote mining)
- Cardano tools (auto-downloaded during setup)

## Example 1: Local Mining

Mine on your local machine in 4 simple commands:

```bash
# 1. Configure
cp config/local.conf.example config/local.conf
# Edit config/local.conf with your settings (workers, data directory, etc.)

# 2. Setup (creates HD wallet, installs dependencies)
./mine setup

# 3. Start mining
./mine start

# 4. Watch live output
./mine watch
```

That's it! Your miner is running with a secure HD wallet.

### Check Status

```bash
# Quick status check
./mine status

# Example output:
# Status: RUNNING ✓
# Wallets: 8
# Total solutions: 3
# Recent solutions:
#   2025-11-15 10:23:45 - addr1qyk9mx... Solution accepted
```

### Stop Mining

```bash
# Stop and automatically backup
./mine stop

# Output shows:
# - Solutions found
# - Backup location
# - Wallet recovery info
```

---

## Example 2: Remote Mining (VPS)

Mine on a remote server via SSH:

```bash
# 1. Configure
cp config/s1.conf.example config/s1.conf
# Edit config/s1.conf:
#   SSH_HOST=root@51.159.135.76
#   REMOTE_DIR=/root/miner
#   DATA_DIR=/Users/yourname/mining/data  (local path!)

# 2. Setup remote server (deploys code, creates wallet)
./mine setup-s1

# 3. Start mining
./mine start-s1

# 4. Watch output
./mine watch-s1

# 5. Check status
./mine status-s1

# 6. Stop (auto-downloads backup to local DATA_DIR)
./mine stop-s1
```

### Multiple Servers

```bash
# Setup all servers
cp config/s1.conf.example config/s2.conf  # Edit for server 2
cp config/s1.conf.example config/s3.conf  # Edit for server 3

./mine setup-s1
./mine setup-s2
./mine setup-s3

# Start all
./mine start-s1
./mine start-s2
./mine start-s3

# Check all at once
./mine status-all

# Example output:
# Host: s1 (51.159.135.76)
# Status: RUNNING ✓
# Solutions: 12
#
# Host: s2 (51.159.135.77)
# Status: RUNNING ✓
# Solutions: 15
#
# Total solutions: 27
```

---

## Example 3: Backup and Recovery

### Create Backup

```bash
# Manual backup (local)
./mine backup

# Manual backup (remote - downloads to local)
./mine backup-s1

# Backup all servers
./mine backup-all
```

### Backup Contents

Each backup includes:
- **mnemonic.txt**: Your 24-word seed phrase (CRITICAL!)
- **wallets.json**: All wallet addresses and keys
- **REPORT.txt**: Solution summary showing which wallets mined NIGHT
- **miner.log**: Complete mining logs
- Other data files (challenges, balances)

### Backup Location

```bash
# Backups are stored in:
data/
├── local/
│   ├── backup-20251115-143022/
│   ├── backup-20251115-180945/
│   └── latest -> backup-20251115-180945/
├── s1/
│   ├── backup-20251115-143055/
│   └── latest -> backup-20251115-143055/
└── s2/
    └── ...
```

---

## Example 4: Understanding Which Wallets Have Solutions

After stopping or backing up, check the REPORT.txt file:

```bash
# View latest backup report (local)
cat data/local/latest/REPORT.txt

# View latest backup report (remote server s1)
cat data/s1/latest/REPORT.txt
```

### Example Report Output

```
========================================
MIDNIGHT MINER - BACKUP REPORT
========================================
Host: s1
Date: 2025-11-15 14:30:22 UTC
Backup: /Users/yourname/mining/data/s1/backup-20251115-143022

========================================
MINING SUMMARY
========================================
Total Wallets: 8
Total Solutions: 5

========================================
WALLET DETAILS
========================================

Wallet 0: addr1qyk9mx70qmpxwd0vn9tv3lgthfls9e4e87djkcgcn5jeg...
  Solutions: 0

Wallet 1: addr1qxvx843vn3m2qf0psp9y4s0kgnzgwjx75fyj6fyrp5ns3...
  Solutions: 0

Wallet 2: addr1qyncsq9wxulhwqae2n68a57yqj7zetlcx9yhptadrjpnw...
  Solutions: 1
  First solution: 2025-11-15 10:23:45
  Last solution: 2025-11-15 10:23:45

Wallet 5: addr1v98jgsalz4qyye0exx5ntqtwqus5tt7rkuxayhnpr5ng7...
  Solutions: 2
  First solution: 2025-11-15 11:15:22
  Last solution: 2025-11-15 12:48:33

Wallet 7: addr1v9egju9gruqcgpj4kjuuhwm75k074yhvnf2ajrhga8qkd...
  Solutions: 2
  First solution: 2025-11-15 11:32:10
  Last solution: 2025-11-15 12:05:18
```

**Key Info:**
- **Wallets with solutions**: 2, 5, and 7 found NIGHT
- **Wallets without solutions**: 0, 1, 3, 4, 6 have no rewards yet
- **Account numbers**: In Eternl, you'll switch to Account 2, 5, and 7 to access rewards

---

## Example 5: Restoring in Eternl/Nufi Wallet

### Step 1: Get Your Mnemonic

```bash
# From backup
cat data/local/latest/mnemonic.txt

# Or from original HD wallet
cat hd-wallets/mnemonic.txt
```

Example mnemonic (24 words):
```
rare energy visit fire ready surge gate around usage any elegant piano
gaze multiply moment rule guard busy material biology gentle saddle caught knife
```

### Step 2: Import to Eternl

1. Open Eternl wallet
2. Select "Restore Wallet"
3. Choose "Cardano" network
4. Select "24 words" recovery phrase
5. Enter your mnemonic (24 words from above)
6. Set a wallet name (e.g., "Mining Server 1")
7. Set a spending password
8. Click "Restore"

### Step 3: Switch Between Accounts

Eternl automatically discovers all your accounts (wallets):

1. In Eternl, click your wallet name at top
2. You'll see: "Account 0", "Account 1", "Account 2", etc.
3. Each account corresponds to a wallet from your miner:
   - Account 0 = Wallet 0 (from wallets.json)
   - Account 1 = Wallet 1
   - Account 2 = Wallet 2 (has solutions!)
   - ...

4. Click "Account 2" to switch to that wallet
5. You'll see its address matches the report: `addr1qyncsq9wxul...`
6. Check your NIGHT balance!

### Step 4: Verify on sm.midnight.gd

1. Copy the address from Eternl (e.g., Account 2's address)
2. Go to https://sm.midnight.gd
3. Paste the address
4. See your solutions and NIGHT balance

### Step 5: Access All Wallets with Solutions

Based on the REPORT.txt example above:

```bash
# In Eternl, switch to:
Account 2  → addr1qyncsq... (1 solution)
Account 5  → addr1v98jgs... (2 solutions)
Account 7  → addr1v9egju... (2 solutions)

# Total: 5 solutions across 3 wallets
```

### Important Recovery Notes

- **One mnemonic controls all wallets**: The 24 words recover all 8 (or 16, or however many you created) wallets
- **Account number = Wallet index**: Account 0 in Eternl = Wallet 0 in miner
- **No solutions = Empty wallet**: Accounts without solutions will show 0 NIGHT balance
- **Backup the mnemonic securely**: Store it in a password manager or write it down offline

---

## Common Operations

### Check All Servers at Once

```bash
./mine status-all
```

### Backup All Servers

```bash
./mine backup-all
```

### Stop All Servers

```bash
./mine stop-all
# Stops mining and downloads backups for all configured servers
```

### Re-run Setup (if needed)

```bash
# To regenerate wallets, first delete existing HD wallet:
rm -rf hd-wallets/ wallets.json
./mine setup

# WARNING: This creates NEW wallets. Only do this if:
# - You haven't mined any solutions yet, OR
# - You have backed up your old mnemonic and want fresh wallets
```

---

## Troubleshooting

### Miner won't start

```bash
# Check logs
./mine watch

# For remote
./mine watch-s1
```

### Can't connect to remote server

```bash
# Test SSH connection
ssh root@51.159.135.76

# If connection works, check config/s1.conf:
# - SSH_HOST is correct
# - REMOTE_DIR exists
```

### No solutions showing up

```bash
# Check status
./mine status

# Solutions take time! Mining is probabilistic
# Keep watching output for "Solution accepted" messages
```

### Lost mnemonic

```bash
# Check your latest backup
cat data/local/latest/mnemonic.txt

# Or original location
cat hd-wallets/mnemonic.txt

# Or initial backup created during setup
cat data/local/initial-backup/mnemonic.txt
```

---

## Next Steps

- Read [README.md](README.md) for complete project documentation
- Check [doc/](doc/) for detailed technical information
- Monitor your miners regularly with `./mine status-all`
- Backup regularly with `./mine backup-all`
- Keep your mnemonic safe - it's your only way to recover NIGHT rewards!

Happy mining!
