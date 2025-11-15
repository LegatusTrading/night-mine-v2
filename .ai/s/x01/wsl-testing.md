# WSL Testing Plan

Testing Midnight Miner v2 on Windows Subsystem for Linux (WSL)

## Pre-requisites

1. **WSL installed** (WSL2 recommended)
   ```powershell
   # In PowerShell (Admin)
   wsl --install
   ```

2. **Ubuntu/Debian on WSL**
   ```bash
   wsl --list --verbose
   ```

3. **Python 3.10-3.13** (NOT 3.14)
   ```bash
   python3 --version
   # If 3.14, install 3.13:
   sudo apt update
   sudo apt install python3.13 python3.13-venv
   ```

4. **Git installed**
   ```bash
   git --version
   ```

## Test Plan

### 1. Clone Repository

```bash
cd ~
git clone https://github.com/LegatusTrading/night-mine-v2.git
cd night-mine-v2
```

**Expected:**
- Repository clones successfully
- No large Cardano binaries (lib/cardano-* should NOT exist yet)
- Ashmaize binaries present:
  - `lib/linux-x64/ashmaize_py.so`
  - `ashmaize_loader.py`

**Verify:**
```bash
ls -lh lib/
# Should show: linux-x64/ and macos-arm64/
# Should NOT show: cardano-address or cardano-cli

ls -lh lib/cardano-* 2>/dev/null
# Should output: No such file or directory
```

---

### 2. Configure Local Mining

```bash
cp config/local.conf.example config/local.conf
nano config/local.conf  # or vim/code
```

**Edit:**
```bash
WORKERS=4              # Adjust to your CPU cores
WALLETS=4              # Match workers or 2x workers
NETWORK=mainnet
DATA_DIR=$HOME/mining-data
```

**Expected:**
- Config file created
- Settings appropriate for WSL/Windows machine

---

### 3. Run Setup

```bash
./mine setup
```

**Expected Output:**
```
Setting up Midnight Miner on local...
Detecting system...
Linux x86_64

Installing Python dependencies...
Using python3.13 (Python 3.13.x)
✓ venv created with Python 3.13

Checking Cardano tools...
Downloading Cardano tools...
Downloading cardano-address...
✓ cardano-address downloaded
Downloading cardano-cli...
✓ cardano-cli downloaded

Generating HD wallet with 4 accounts...
✓ HD wallet generated

Importing HD wallets to miner format...
✓ Wallets imported

Initial backup saved to: ~/mining-data/local/initial-backup/
CRITICAL: Save the mnemonic securely!

[24-word mnemonic displayed]

Setup complete for local!
```

**Verify:**
```bash
# Check Python version in venv
source .venv/bin/activate
python --version
# Should be 3.10, 3.11, 3.12, or 3.13 (NOT 3.14)

# Check Cardano tools downloaded
ls -lh lib/cardano-*
# Should show:
# lib/cardano-address (50-100MB)
# lib/cardano-cli (200-300MB)

# Verify tools work
lib/cardano-address --version
# Expected: 4.0.1 @...

lib/cardano-cli --version
# Expected: cardano-cli 10.1.3.0 - linux-x86_64 - ghc-9.8

# Check HD wallet created
ls -la hd-wallets/
# Should show: mnemonic.txt, root.prv, account-0/, account-1/, etc.

# Check backup created
ls -la ~/mining-data/local/initial-backup/
# Should show: mnemonic.txt, wallets.json

# Test ashmaize library
python -c "import ashmaize_loader; ash = ashmaize_loader.init(); print('✓ Ashmaize loaded')"
# Expected: ✓ Ashmaize loaded
```

---

### 4. Start Mining

```bash
./mine start
```

**Expected Output:**
```
Starting Midnight Miner on local...
✓ Miner started
PID: [process_id]

Status for local:
Status: RUNNING ✓
PID: [process_id]
```

**Verify:**
```bash
./mine status
# Should show:
# Status: RUNNING ✓
# PID: [number]
# Wallets: 4
# Total solutions: 0

ps aux | grep miner.py
# Should show running Python process
```

---

### 5. Watch Mining Output

```bash
./mine watch
```

**Expected Output:**
```
Watching important events on local (Ctrl+C to exit)...
Filtering: Solutions, Errors, Worker changes, Challenges

MIDNIGHT MINER - v0.3.1
Configuration:
  Workers: 4
  Wallets to ensure: 4

✓ Loading wallets from wallets.json
✓ Loaded 4 existing wallets

STARTING MINERS
All workers started. Starting dashboard...
```

**Should NOT see:**
- ImportError about Union from _typing
- Segmentation faults
- Python 3.14 incompatibility warnings
- Worker crash loops

**Press Ctrl+C to exit watch mode**

---

### 6. Check Mining Status (After 1-2 minutes)

```bash
./mine status
```

**Expected Output:**
```
Status for local:

Status: RUNNING ✓
PID: [number]
Wallets: 4
Total solutions: 0

Recent solutions (last 5):
  No solutions found yet

Mining activity (last 5 workers):
0    addr1qxm567zngadhklc...   **D17C03                  150,000      1147
1    addr1q8n60vrnjq5hljd...   **D17C03                  150,000      1146
2    addr1qy3ufjskngv6jup...   **D17C03                  140,000      1145
3    addr1q9ntc5evx9swy0s...   **D17C03                  140,000      1147
```

**Verify:**
- All workers showing hash rates (H/s > 0)
- All workers mining same challenge
- No workers stuck at 0 attempts

---

### 7. Stop Mining

```bash
./mine stop
```

**Expected Output:**
```
Stopping Midnight Miner on local...
✓ Miner stopped
Counting solutions...
✓ Total solutions found: 0

Running automatic backup...
Creating backup directory: ~/mining-data/local/backup-[timestamp]/
✓ Backed up: mnemonic.txt
✓ Backed up: wallets.json
✓ Backed up: challenges.json
✓ Backed up: balances.json
✓ Backed up: miner.log
✓ Generated: REPORT.txt

Backup complete!
Location: ~/mining-data/local/backup-[timestamp]/
Symlink updated: ~/mining-data/local/latest -> backup-[timestamp]

Miner stopped and backed up successfully!
```

**Verify:**
```bash
# Check process stopped
ps aux | grep miner.py | grep -v grep
# Should be empty

# Check backup created
ls -la ~/mining-data/local/latest/
# Should show: mnemonic.txt, wallets.json, REPORT.txt, etc.

# Check REPORT.txt
cat ~/mining-data/local/latest/REPORT.txt
# Should show wallet summary
```

---

### 8. Test Save Script

```bash
./save
```

**Expected Output:**
```
Creating backup: ~/blockchain/midnight/data/[timestamp]_night-miner-v2
Backing up config files...
Backing up data directory...
Backing up hd-wallets directory...
Backing up wallets.json...
Creating backup manifest...

✓ Backup complete!
Location: ~/blockchain/midnight/data/[timestamp]_night-miner-v2

Files backed up:
BACKUP_MANIFEST.txt
config/local.conf
data/local/backup-[timestamp]/...
hd-wallets/mnemonic.txt
wallets.json
```

**Verify:**
```bash
ls -la ~/blockchain/midnight/data/
# Should show timestamped backup directory
```

---

## Platform-Specific Tests

### WSL-Specific Checks

1. **Platform Detection:**
   ```bash
   uname -s
   # Expected: Linux (not Windows)

   uname -m
   # Expected: x86_64 (not aarch64)
   ```

2. **Ashmaize Binary:**
   ```bash
   file lib/linux-x64/ashmaize_py.so
   # Expected: ELF 64-bit LSB shared object, x86-64
   ```

3. **Cardano Tools:**
   ```bash
   file lib/cardano-address
   # Expected: ELF 64-bit LSB executable, x86-64

   file lib/cardano-cli
   # Expected: ELF 64-bit LSB executable, x86-64
   ```

4. **Performance:**
   ```bash
   # Check CPU usage
   top
   # Python process should use ~100-400% CPU (4 workers)

   # Check hash rate
   ./mine status
   # Total hash rate should be 4000-8000 H/s (4 workers)
   ```

---

## Troubleshooting

### Issue: Python 3.14 detected

**Solution:**
```bash
sudo apt install python3.13 python3.13-venv
rm -rf .venv
python3.13 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Issue: Cardano tools download fails

**Check:**
```bash
# Test internet connectivity
curl -I https://github.com

# Manually download if needed
cd lib
curl -L -o cardano-address.tar.gz \
  https://github.com/IntersectMBO/cardano-addresses/releases/download/4.0.1/cardano-addresses-4.0.1-linux.tar.gz
tar -xzf cardano-address.tar.gz bin/cardano-address --strip-components=1
chmod +x cardano-address
rm cardano-address.tar.gz
```

### Issue: Workers crash with ImportError

**Check Python version:**
```bash
.venv/bin/python --version
```

If 3.14, recreate venv with 3.13 (see above)

### Issue: Low hash rate

**Check:**
```bash
# CPU cores
nproc
# Adjust WORKERS in config/local.conf to match

# Restart miner
./mine stop
./mine start
```

---

## Success Criteria

✅ **Setup Phase:**
- Python 3.13 (or 3.10-3.12) venv created
- Cardano tools downloaded to lib/
- HD wallet generated (24-word mnemonic)
- Initial backup created

✅ **Mining Phase:**
- All workers running with H/s > 1000
- No ImportError or segmentation faults
- No worker crash loops
- Status command shows clean output

✅ **Stop Phase:**
- Miner stops cleanly
- Automatic backup created
- REPORT.txt generated
- No orphan processes

✅ **WSL-Specific:**
- Platform detected as Linux x86_64
- Linux-specific binaries used
- Performance comparable to native Linux

---

## Notes

- Solutions are rare - 0 solutions after short testing is normal
- Hash rate varies by CPU (1000-1500 H/s per worker typical)
- First run downloads ~300MB (Cardano tools)
- WSL2 recommended over WSL1 for better performance
