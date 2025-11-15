# Next Steps - Testing and Deployment

**Date**: 2025-11-15
**Project**: night-mine-v2
**Status**: Ready for testing

---

## Overview

The night-mine-v2 project is implemented and ready for testing. Follow these steps to verify everything works before production deployment.

**Estimated Time**: 1-2 hours total

---

## Prerequisites

- [ ] Review `agent-out.md` (implementation summary)
- [ ] Review `QUICKSTART.md` (usage examples)
- [ ] Review `README.md` (project overview)
- [ ] Ensure you have:
  - Python 3.8+ installed
  - SSH access to server 51.159.135.76
  - Eternl wallet app/extension ready

---

## Step 1: Local Testing (30 minutes)

### 1.1 Configuration

```bash
cd /Users/psuzzi/projects/mn/night-mine-v2

# Config already created by agent
# Verify it exists
cat config/local.conf

# Should show:
# WORKERS=8
# WALLETS=8
# NETWORK=mainnet
# DATA_DIR=/Users/psuzzi/projects/mn/night-mine-v2/data
```

### 1.2 Setup Environment

```bash
# Run setup (generates HD wallet, installs dependencies)
./mine setup
```

**Expected output**:
```
Setting up Midnight Miner on local...
Installing Python dependencies...
Successfully installed pycardano requests...
Generating HD wallet with 8 accounts...
HD wallet generated
Importing HD wallets to miner format...
Wallets imported
Backing up mnemonic...
Initial backup saved to: data/local/initial-backup/

rare energy visit fire ready surge gate around usage any elegant piano
gaze multiply moment rule guard busy material biology gentle saddle caught knife

Setup complete for local!
```

**Verify**:
```bash
# Check files created
ls -la .venv/              # Python venv
ls -la hd-wallets/         # HD wallet keys
cat hd-wallets/mnemonic.txt # 24-word seed
cat wallets.json           # 8 wallet addresses
cat data/local/initial-backup/mnemonic.txt  # Backed up mnemonic

# All should exist
```

**⚠️ CRITICAL**: Save the mnemonic shown to you!
- Write it down on paper
- Store in password manager
- Keep multiple backups

### 1.3 Verify Wallet Addresses

```bash
# Check all 8 addresses start with addr1q (base address)
cat wallets.json | jq '.[].address'

# All should start with addr1q (NOT addr1v)
# Example:
# "addr1qyk9mx70qmpxwd0vn9tv3lgthfls9e..."
# "addr1qxvx843vn3m2qf0psp9y4s0kgnzgwj..."
```

### 1.4 Start Mining

```bash
# Start the miner
./mine start
```

**Expected output**:
```
Starting Midnight Miner on local...
Starting local miner with 8 workers, 8 wallets...
Miner started (PID: 12345)
Checking status...

Miner is running
Recent output:
2025-11-15 14:30:22 - Starting miner with 8 workers
2025-11-15 14:30:22 - Worker 0 started with wallet addr1qyk9mx...
...
```

**Verify**:
```bash
# Check PID file
cat .miner.pid

# Check log file
tail -20 miner.log

# Should show workers starting, fetching challenges
```

### 1.5 Monitor Mining

```bash
# Watch live output (Ctrl+C to exit)
./mine watch

# In another terminal, check status
./mine status
```

**Expected in logs**:
- Workers fetching challenges
- Mining challenges
- Hopefully: "Solution accepted" (but rare!)

**Let it run for 5-10 minutes** to verify stable operation.

### 1.6 Stop and Backup

```bash
# Stop mining (auto-creates backup)
./mine stop
```

**Expected output**:
```
Stopping Midnight Miner on local...
Miner stopped
Counting solutions...
Total solutions found: 0

Running automatic backup...
Creating backup for local...
Backing up local files...
Generating solution report...
Backup created: data/local/backup-20251115-143022/

[REPORT.txt shown]

Latest backup linked: data/local/latest
Miner stopped and backed up successfully!
```

**Verify backup**:
```bash
# Check backup created
ls -la data/local/

# Should show:
# initial-backup/
# backup-20251115-143022/
# latest -> backup-20251115-143022/

# Check backup contents
ls -la data/local/latest/
cat data/local/latest/REPORT.txt
cat data/local/latest/mnemonic.txt
```

**✅ Local testing complete!**

---

## Step 2: Recovery Testing - Eternl (20 minutes)

**CRITICAL**: Test recovery BEFORE any significant mining!

### 2.1 Get Mnemonic

```bash
# Get mnemonic from backup
cat data/local/latest/mnemonic.txt

# Copy the 24 words
```

### 2.2 Install Eternl

**Browser Extension**:
- Chrome: https://chrome.google.com/webstore → search "Eternl"
- Firefox: https://addons.mozilla.org → search "Eternl"
- Or use mobile app

### 2.3 Restore Wallet in Eternl

1. Open Eternl
2. Click "Add Wallet"
3. Select "Restore Wallet"
4. Choose:
   - Network: "Cardano"
   - Recovery phrase: "24 words"
5. Enter your 24 words (in exact order)
6. Set wallet name: "Test Local Mining"
7. Set spending password (your choice)
8. Click "Restore"
9. Wait for sync (30-60 seconds)

### 2.4 Verify Address Match

**In Eternl**:
- You should see "Account 0" by default
- Click "Receive" tab
- Copy the address shown

**In terminal**:
```bash
# Get Wallet 0 address from miner
cat wallets.json | jq -r '.[0].address'
```

**Compare**:
- Eternl Account 0 address
- vs wallets.json Wallet 0 address

**They should be EXACTLY the same!**

Example:
```
Eternl Account 0: addr1qyk9mx70qmpxwd0vn9tv3lgthfls9e4e87djkcgcn5jeg...
wallets.json [0]:  addr1qyk9mx70qmpxwd0vn9tv3lgthfls9e4e87djkcgcn5jeg...
✅ MATCH!
```

### 2.5 Check All Accounts

**In Eternl**:
1. Click wallet name at top
2. You should see: "Account 0", "Account 1", "Account 2", etc.
3. Switch to each account
4. Each account = one wallet from miner

**Mapping**:
- Eternl Account 0 = Miner Wallet 0
- Eternl Account 1 = Miner Wallet 1
- ...
- Eternl Account 7 = Miner Wallet 7

**Verify a few**:
```bash
# Get addresses from miner
cat wallets.json | jq -r '.[0].address'  # Should match Eternl Account 0
cat wallets.json | jq -r '.[2].address'  # Should match Eternl Account 2
cat wallets.json | jq -r '.[5].address'  # Should match Eternl Account 5
```

### 2.6 Test sm.midnight.gd

1. In Eternl, copy Account 0 address
2. Go to: https://sm.midnight.gd
3. Paste address
4. Press Enter

**Expected**: Address is accepted (even if 0 solutions)

**If you see "Invalid format"**: Your addresses are NOT base addresses!
- This would be a critical bug
- Stop and investigate

**✅ Recovery testing complete!**

---

## Step 3: Remote Testing - Server s1 (30 minutes)

### 3.1 Verify Configuration

```bash
# Config already created by agent
cat config/s1.conf

# Should show:
# WORKERS=8
# WALLETS=8
# NETWORK=mainnet
# DATA_DIR=/Users/psuzzi/projects/mn/night-mine-v2/data
# SSH_HOST=root@51.159.135.76
# REMOTE_DIR=/root/miner
```

### 3.2 Test SSH Connection

```bash
# Verify you can connect
ssh root@51.159.135.76

# If connected, exit
exit
```

**If SSH fails**:
- Check SSH keys: `ssh-add -l`
- Add key if needed: `ssh-add ~/.ssh/id_rsa`
- Or use password authentication

### 3.3 Deploy and Setup

```bash
# Run remote setup (deploys code, generates HD wallet)
./mine setup-s1
```

**Expected output**:
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
Initial backup downloaded to: data/s1/initial-backup/

[24-word mnemonic shown]

Setup complete for s1!
```

**⚠️ IMPORTANT**: This is a DIFFERENT mnemonic than local!
- Each server has its own mnemonic
- Back it up separately

**Verify**:
```bash
# Check backup downloaded locally
ls -la data/s1/initial-backup/
cat data/s1/initial-backup/mnemonic.txt

# Check files on server
ssh root@51.159.135.76 "ls -la /root/miner/"
# Should show: hd-wallets/, wallets.json, .venv/, etc.
```

### 3.4 Start Remote Mining

```bash
# Start miner on s1
./mine start-s1
```

**Expected output**:
```
Starting Midnight Miner on s1...
Starting miner on root@51.159.135.76...
Miner service started on s1
Checking status...

Miner is running on s1
Recent output:
2025-11-15 14:45:00 - Starting miner with 8 workers
...
```

**Verify**:
```bash
# Check status
./mine status-s1

# Should show:
# Status: RUNNING ✓
# Wallets: 8
# Total solutions: 0
```

### 3.5 Monitor Remote Mining

```bash
# Watch live output (Ctrl+C to exit)
./mine watch-s1

# Should see workers fetching challenges, mining
```

**Let it run for 5-10 minutes** to verify stable.

### 3.6 Manual Backup

```bash
# Create manual backup (without stopping)
./mine backup-s1
```

**Expected output**:
```
Creating backup for s1...
Downloading files from root@51.159.135.76...
Generating solution report...
Backup created: data/s1/backup-20251115-150000/
[REPORT.txt shown]
Latest backup linked: data/s1/latest
```

**Verify**:
```bash
# Check backup downloaded to local
ls -la data/s1/
cat data/s1/latest/REPORT.txt
cat data/s1/latest/mnemonic.txt
```

### 3.7 Stop Remote Mining

```bash
# Stop s1 (auto-creates final backup)
./mine stop-s1
```

**Expected**:
```
Stopping Midnight Miner on s1...
Miner stopped on s1
Counting solutions...
Total solutions found: 0

Running automatic backup...
[Backup created]
```

**Verify**:
```bash
# Check miner stopped on server
./mine status-s1
# Should show: Status: STOPPED ✗

# Check final backup
cat data/s1/latest/REPORT.txt
```

**✅ Remote testing complete!**

---

## Step 4: Multi-Server Testing (10 minutes)

### 4.1 Test Status All

```bash
# Should show both local and s1
./mine status-all
```

**Expected**:
```
Status for all configured servers:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Host: s1 (root@51.159.135.76)
Status: STOPPED ✗
Solutions: 0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total solutions across all servers: 0
```

**Note**: Only shows REMOTE servers (not local)

### 4.2 Test Backup All

```bash
# Backup all configured servers
./mine backup-all
```

**Should create backups for all servers**.

**✅ Multi-server testing complete!**

---

## Step 5: Production Deployment Checklist

### 5.1 Pre-Deployment

- [ ] All tests passed
- [ ] Recovery tested in Eternl (addresses match)
- [ ] Mnemonics backed up securely (local + s1)
  - [ ] Password manager
  - [ ] Written on paper
  - [ ] Multiple secure locations
- [ ] Verified .gitignore in place (no sensitive data committed)
- [ ] Read QUICKSTART.md
- [ ] Read relevant sections of README.md

### 5.2 Deploy to Production

**For s1 (already deployed)**:
```bash
# Start mining
./mine start-s1

# Verify
./mine status-s1

# Monitor for a bit
./mine watch-s1
# Ctrl+C after verifying stable
```

**For additional servers (s2, s3, s4...)**:
```bash
# Create config for each
cp config/s1.conf config/s2.conf
# Edit s2.conf with new SSH_HOST

# Deploy
./mine setup-s2
./mine start-s2

# Repeat for s3, s4...
```

### 5.3 Ongoing Operations

**Daily**:
```bash
# Check all servers
./mine status-all
```

**Weekly**:
```bash
# Backup all servers
./mine backup-all

# Review backups
cat data/s1/latest/REPORT.txt
cat data/s2/latest/REPORT.txt
# etc.
```

**When mining phase ends**:
```bash
# Stop all servers (creates final backups)
./mine stop-all

# Review all solution reports
cat data/*/latest/REPORT.txt

# Import mnemonics to Eternl
# Check accounts with solutions
# Claim NIGHT tokens
```

---

## Troubleshooting

### Issue: Setup Fails Locally

**Error**: "Python not found" or "venv creation failed"

**Solution**:
```bash
# Install Python 3.8+
# macOS:
brew install python3

# Check version
python3 --version
```

### Issue: SSH Connection Failed

**Error**: "Permission denied" or "Connection refused"

**Solution**:
```bash
# Check SSH key
ssh-add -l

# Add key if needed
ssh-add ~/.ssh/id_rsa

# Test connection
ssh root@51.159.135.76
```

### Issue: Addresses Don't Match in Eternl

**Problem**: Eternl Account 0 shows different address than wallets.json

**Possible causes**:
1. Wrong mnemonic imported
2. Wrong network (testnet vs mainnet)
3. Wrong account (check Account 0, not 1 or 2)

**Solution**:
1. Verify mnemonic exactly matches backup
2. Verify "Cardano Mainnet" in Eternl
3. Verify looking at Account 0 (not another account)

### Issue: Miner Won't Start

**Error**: Miner fails to start or immediately crashes

**Solution**:
```bash
# Check logs
./mine watch

# Common issues:
# - Missing wallets.json (run ./mine setup)
# - Port already in use (another miner running)
# - Python dependencies missing (run ./mine setup)
```

### Issue: No Solutions After Hours

**This is normal!**

- Solutions are RARE
- Mining is probabilistic
- Could be hours or days between solutions
- Keep mining and monitoring

---

## Post-Testing Actions

### After Successful Testing

1. **Commit to git** (with .gitignore in place):
   ```bash
   cd /Users/psuzzi/projects/mn/night-mine-v2
   git status  # Verify no sensitive files
   git add .
   git commit -m "Complete night-mine-v2 implementation"
   ```

2. **Start production mining**:
   ```bash
   ./mine start-s1
   # Add more servers as needed
   ```

3. **Set up monitoring** (optional):
   ```bash
   # Add to crontab for daily status emails
   0 9 * * * cd /path/to/night-mine-v2 && ./mine status-all | mail -s "Mining Status" you@email.com
   ```

4. **Regular backups** (optional):
   ```bash
   # Add to crontab for daily backups
   0 3 * * * cd /path/to/night-mine-v2 && ./mine backup-all
   ```

### Mnemonic Security

**Critical**: Ensure mnemonics are backed up:
- [ ] data/local/initial-backup/mnemonic.txt backed up
- [ ] data/s1/initial-backup/mnemonic.txt backed up
- [ ] Mnemonics stored in password manager
- [ ] Mnemonics written on paper (offline backup)
- [ ] Multiple backup locations
- [ ] Backups stored securely (encrypted, safe, etc.)

**Test recovery** periodically:
- Import mnemonic to Eternl on different device
- Verify addresses still match
- Confirms mnemonic works

---

## Timeline Summary

| Step | Duration | Description |
|------|----------|-------------|
| 1. Local Testing | 30 min | Setup, mine, stop, backup |
| 2. Recovery Testing | 20 min | Eternl import, address verification |
| 3. Remote Testing | 30 min | Deploy s1, mine, backup |
| 4. Multi-Server | 10 min | Test status-all, backup-all |
| 5. Production Deployment | Ongoing | Deploy to all servers |

**Total testing time**: ~90 minutes

---

## Success Criteria

### Must Pass

- [x] Local setup completes without errors
- [x] HD wallet generated (24 words)
- [x] 8 wallets created (all addr1q...)
- [x] Miner starts successfully
- [x] Logs show workers mining
- [x] Stop creates backup automatically
- [x] REPORT.txt generated
- [x] Eternl import successful
- [x] Addresses match exactly (Eternl Account N = Miner Wallet N)
- [x] Remote deployment successful
- [x] Remote miner starts and runs
- [x] Remote backup downloads to local
- [x] status-all works
- [x] backup-all works

### Nice to Have

- [ ] Found at least 1 solution (rare, may not happen in testing)
- [ ] Verified solution on sm.midnight.gd
- [ ] Tested recovery with solution-containing wallet

---

## Next Steps After Testing

1. **If all tests pass**:
   - Deploy to production servers
   - Start mining
   - Monitor daily
   - Backup weekly

2. **If tests fail**:
   - Review error messages
   - Check troubleshooting section
   - Review agent-out.md for implementation details
   - Fix issues
   - Re-test

3. **When mining phase ends**:
   - Stop all servers (`./mine stop-all`)
   - Review all REPORT.txt files
   - Import mnemonics to Eternl
   - Check accounts with solutions
   - Claim NIGHT tokens

---

## Contact/Support

**Documentation**:
- `QUICKSTART.md` - Quick start guide
- `README.md` - Complete project docs
- `doc/architecture.md` - System design
- `doc/hd-wallets.md` - HD wallet guide
- `doc/operations.md` - Operations guide
- `doc/recovery.md` - Recovery procedures

**AI Agent**: Review `agent-out.md` for implementation details

---

**Good luck with testing and mining! 🚀**

**Remember**: Mining phase ends in days - test quickly and deploy!
