# Wallet Recovery Procedures

Complete guide to recovering your wallets and NIGHT tokens using your backed-up mnemonic.

---

## Recovery Scenarios

### Scenario 1: Normal Recovery (Have Backup)

**Situation**: Mining complete, want to access NIGHT in wallet

**What you have**:
- ✅ Backup with mnemonic
- ✅ Backup report showing solutions

**Recovery**: Simple Eternl import

---

### Scenario 2: Server Lost/Corrupted

**Situation**: Server died, disk failed, or data corrupted

**What you have**:
- ✅ Local backup (in data/ directory)
- ✅ Mnemonic backed up

**Recovery**: Import to Eternl, continue mining on new server if desired

---

### Scenario 3: Emergency Recovery

**Situation**: All servers lost, only have mnemonic written down

**What you have**:
- ✅ 24-word mnemonic (written on paper, password manager, etc.)
- ❌ No REPORT.txt (don't know which wallets have solutions)

**Recovery**: Import to Eternl, check all accounts on sm.midnight.gd

---

## Prerequisites for Recovery

### What You Need

**Essential**:
- 24-word mnemonic (from any backup)

**Helpful** (but not required):
- REPORT.txt (tells you which wallets have solutions)
- wallets.json (shows addresses)

**Tools**:
- Eternl wallet (https://eternl.io)
- OR Nufi wallet (https://nu.fi)
- OR any BIP39/CIP-1852 compatible Cardano wallet

### Where to Find Mnemonic

**Best locations**:
1. `data/{host}/latest/mnemonic.txt` (latest backup)
2. `data/{host}/initial-backup/mnemonic.txt` (from setup)
3. Any timestamped backup: `data/{host}/backup-YYYYMMDD-HHMMSS/mnemonic.txt`
4. Your personal secure storage (password manager, paper backup)

**Check**:
```bash
# Local
cat data/local/latest/mnemonic.txt

# Remote server backups
cat data/s1/latest/mnemonic.txt
cat data/s2/latest/mnemonic.txt
cat data/s3/latest/mnemonic.txt
```

---

## Recovery Method 1: Eternl Wallet

### Step 1: Install Eternl

**Browser Extension**:
- Chrome: Chrome Web Store → "Eternl"
- Firefox: Firefox Add-ons → "Eternl"
- Brave: Same as Chrome

**Mobile**:
- iOS: App Store → "Eternl"
- Android: Google Play → "Eternl"

---

### Step 2: Restore Wallet

1. **Open Eternl**
2. **Click "Add Wallet"**
3. **Select "Restore Wallet"**

4. **Choose Network**: "Cardano"

5. **Select Mnemonic Length**: "24 words"

6. **Enter Your Mnemonic**:
   ```
   rare energy visit fire ready surge gate around usage any elegant piano
   gaze multiply moment rule guard busy material biology gentle saddle caught knife
   ```
   - Enter words in exact order
   - Use autocomplete (Eternl suggests valid BIP39 words)
   - Verify spelling carefully

7. **Set Wallet Name**: e.g., "Mining Server 1"

8. **Set Spending Password**:
   - Choose a strong password
   - Required for sending transactions
   - Does NOT affect recovery (only for this device)

9. **Click "Restore"**

**Wait**: Eternl syncs with blockchain (may take 30-60 seconds)

---

### Step 3: Verify Address

**Eternl shows Account 0 by default**

1. **Click "Receive" tab**
2. **Copy the address shown**
3. **Compare with backup**:
   ```bash
   cat data/s1/latest/wallets.json | jq '.[0].address'
   ```

**Expected**:
- Eternl Account 0 address **exactly matches** Wallet 0 from wallets.json
- Both start with `addr1q...` (base address)

**If they don't match**: You may have:
- Wrong mnemonic
- Wrong network (mainnet vs testnet)
- Wrong wallet type (check it's Cardano Shelley)

---

### Step 4: Switch to Accounts with Solutions

**Check which accounts have NIGHT**:
```bash
cat data/s1/latest/REPORT.txt
```

**Example report**:
```
Wallet 2: addr1qyncsq...
  Solutions: 1

Wallet 5: addr1v98jgs...
  Solutions: 2

Wallet 7: addr1v9egju...
  Solutions: 2
```

**In Eternl**:

1. **Click wallet name** at top of screen
2. **See list**: "Account 0", "Account 1", "Account 2", etc.
3. **Click "Account 2"** (Wallet 2)
   - See its receive address
   - Should match report address
   - Check balance (should show NIGHT!)

4. **Click "Account 5"** (Wallet 5)
   - See balance

5. **Click "Account 7"** (Wallet 7)
   - See balance

---

### Step 5: Verify on sm.midnight.gd

**For each account with solutions**:

1. **In Eternl**: Copy the account's receive address

2. **Go to**: https://sm.midnight.gd

3. **Paste address** in search box

4. **Press Enter**

**You should see**:
- Total solutions for this address
- NIGHT balance
- Solution history with timestamps
- Points earned

**Example**:
```
Address: addr1qyncsq9wxulhwqae2n68a57yqj7zetlcx9yhptadrjpnw...
Solutions: 1
NIGHT Balance: 30,000
Points: 30,000
```

---

### Step 6: Send NIGHT (Optional)

**When ready to consolidate or transfer**:

1. **In Eternl**: Switch to account with NIGHT

2. **Click "Send" tab**

3. **Enter**:
   - Recipient address (your main wallet, exchange, etc.)
   - Amount (in NIGHT)

4. **Enter spending password**

5. **Click "Send"**

6. **Confirm transaction**

**Note**: Each account can send independently (they're separate wallets)

---

## Recovery Method 2: Nufi Wallet

### Similar to Eternl

**Nufi Wallet**: https://nu.fi

**Process**:
1. Install Nufi browser extension
2. "Restore Wallet"
3. Enter 24-word mnemonic
4. Select Cardano network
5. Wallet restored with all accounts

**Differences**:
- UI slightly different
- Account switching similar
- Full BIP39/CIP-1852 compatibility

---

## Recovery Method 3: Daedalus

### Full Node Wallet

**Daedalus**: https://daedaluswallet.io

**Note**: Downloads entire blockchain (~100 GB)

**Process**:
1. Install Daedalus
2. Wait for blockchain sync (hours to days)
3. "Restore Wallet"
4. Enter 24-word mnemonic
5. Select "Shelley Wallet"

**Pros**:
- Full node (most secure)
- Official IOHK wallet

**Cons**:
- Large download
- Long sync time
- Resource intensive

---

## Without Backup Report

### Situation

You have mnemonic but lost REPORT.txt. Don't know which accounts have solutions.

### Strategy: Check All Accounts

**In Eternl**:

1. **Restore wallet** with mnemonic (steps above)

2. **Eternl automatically discovers** accounts with transactions

3. **Check each account**:
   - Account 0: Check balance
   - Account 1: Check balance
   - Account 2: Check balance
   - ...
   - Continue until you find all with NIGHT

**Or use sm.midnight.gd**:

For each account 0-15 (or however many wallets you created):

1. Get address from Eternl
2. Check on sm.midnight.gd
3. Note which have solutions

---

## Emergency: Only Have Mnemonic Written Down

### No Access to Computers

**What to do**:

1. **Wait until you have secure access** to:
   - Personal computer (not public/shared)
   - Trusted phone
   - Secure network (not public WiFi)

2. **Install Eternl** on secure device

3. **Restore wallet**:
   - Enter 24 words carefully
   - Verify each word
   - Don't rush

4. **Check all accounts** for NIGHT balance

**Security**:
- Don't enter mnemonic on public/untrusted devices
- Don't take photos of mnemonic
- Don't email or message mnemonic
- Keep mnemonic offline when possible

---

## Recovery Verification Checklist

### Before Starting

- [ ] Have 24-word mnemonic
- [ ] Words are in correct order
- [ ] Using secure device and network
- [ ] Have REPORT.txt (optional but helpful)

### After Restoring in Eternl

- [ ] Account 0 address matches wallets.json
- [ ] Found accounts with solutions (per REPORT.txt)
- [ ] Verified balances on sm.midnight.gd
- [ ] All expected NIGHT accounted for

### Final Steps

- [ ] Backed up Eternl wallet (spending password)
- [ ] Tested sending small amount (optional)
- [ ] Mnemonic still secured in multiple locations
- [ ] Deleted any digital copies of mnemonic from unsecure locations

---

## Common Recovery Issues

### Issue: Address Doesn't Match

**Eternl shows**: `addr1q85wqu...`
**Backup shows**: `addr1qyk9mx...`

**Causes**:
1. Wrong mnemonic
2. Wrong account (check you're looking at Account 0)
3. Wrong network (mainnet vs testnet)

**Solution**:
- Double-check mnemonic word-by-word
- Verify Account 0 in Eternl
- Confirm "Cardano Mainnet" selected

---

### Issue: No Balance Showing

**Eternl shows**: 0 NIGHT

**Causes**:
1. Wrong account (solutions on different account)
2. Blockchain not synced yet
3. No solutions actually found

**Solution**:
- Check REPORT.txt for which accounts have solutions
- Wait for Eternl to fully sync
- Verify on sm.midnight.gd

---

### Issue: Can't Remember Spending Password

**Important**: Spending password is NOT the mnemonic

**Spending password**:
- Set when you restored wallet in Eternl
- Only for THIS device
- NOT needed for recovery

**Solution**:
- Delete Eternl wallet
- Restore again with mnemonic
- Set NEW spending password

**The mnemonic is all you need to recover funds!**

---

### Issue: Only Some Accounts Show

**Eternl shows**: Accounts 0-3
**Should have**: Accounts 0-7

**Cause**: Eternl only shows accounts with transactions

**Solution**:
- Accounts without solutions won't show
- This is normal
- Check REPORT.txt to know which should have NIGHT

---

## Advanced Recovery

### Recover to Command Line

**For advanced users**: Use cardano-cli

```bash
# 1. Generate root key from mnemonic
echo "rare energy visit..." | cardano-address key from-recovery-phrase Shelley > root.prv

# 2. Derive account key
cat root.prv | cardano-address key child 1852H/1815H/0H > account-0.prv

# 3. Derive payment key
cat account-0.prv | cardano-address key child 0/0 > payment.skey

# 4. Derive stake key
cat account-0.prv | cardano-address key child 2/0 > stake.skey

# 5. Build address
# (Same process as generate-hd-wallet.sh)
```

**Use case**: Automated recovery, scripting, no GUI

---

### Recover to Hardware Wallet

**Ledger/Trezor** support BIP39 mnemonic import

**Process**:
1. Import mnemonic to hardware wallet
2. Connect hardware wallet to Eternl/Nufi
3. Access accounts

**Benefit**: Enhanced security (private keys never on computer)

---

## Multi-Server Recovery

### Recovering All Servers

**You have**:
- Server 1: 8 wallets (accounts 0-7)
- Server 2: 8 wallets (accounts 0-7)
- Server 3: 8 wallets (accounts 0-7)

**Each server has different mnemonic!**

### Strategy

**In Eternl**:

1. **Add Wallet #1**: Restore with server 1 mnemonic
   - Name it "Server 1"
   - Check accounts 0-7

2. **Add Wallet #2**: Restore with server 2 mnemonic
   - Name it "Server 2"
   - Check accounts 0-7

3. **Add Wallet #3**: Restore with server 3 mnemonic
   - Name it "Server 3"
   - Check accounts 0-7

**Result**: Three separate wallets in Eternl, each with 8 accounts

**Switching**:
- Click wallet name → Select "Server 1", "Server 2", or "Server 3"
- Then select account within that wallet

---

### If Using Same Mnemonic (Advanced Setup)

**If you used the same mnemonic for all servers with different account ranges**:

Example:
- Server 1: Accounts 0-15
- Server 2: Accounts 16-31
- Server 3: Accounts 32-47

**In Eternl**:
1. Restore wallet ONCE with the mnemonic
2. All accounts 0-47 will show (if they have transactions)
3. Accounts 0-15: Server 1 wallets
4. Accounts 16-31: Server 2 wallets
5. Accounts 32-47: Server 3 wallets

**Benefit**: One mnemonic, all servers!

---

## Security Best Practices

### Mnemonic Storage

**DO**:
- ✅ Write on paper, store in safe
- ✅ Use password manager (encrypted)
- ✅ Store in multiple secure locations
- ✅ Keep offline backups
- ✅ Tell trusted person where to find it (in case of emergency)

**DON'T**:
- ❌ Email or message it
- ❌ Store in plain text file
- ❌ Take photos of it
- ❌ Store on cloud without encryption
- ❌ Share with anyone

### During Recovery

**DO**:
- ✅ Use secure, private device
- ✅ Use secure network (home, VPN)
- ✅ Verify Eternl download is official
- ✅ Double-check each word

**DON'T**:
- ❌ Use public computer
- ❌ Use public WiFi
- ❌ Rush the process
- ❌ Skip verification steps

### After Recovery

**DO**:
- ✅ Keep mnemonic secured
- ✅ Test sending small amount (optional)
- ✅ Consider hardware wallet for large amounts
- ✅ Keep backup mnemonic updated if you derive more accounts

**DON'T**:
- ❌ Delete all backups (keep multiple)
- ❌ Share spending password (device-specific, not important)
- ❌ Assume wallet is invincible (stay vigilant)

---

## Recovery Testing

### Recommended: Test Before Mining Ends

**Why test**:
- Verify mnemonic works
- Verify addresses match
- Practice recovery process
- Find issues early

**How to test**:

1. **After setup** but before significant mining:
   ```bash
   ./mine setup
   # Miner starts, finds 0-1 solutions
   ```

2. **Get mnemonic**:
   ```bash
   cat data/local/initial-backup/mnemonic.txt
   ```

3. **Import to Eternl**:
   - Follow recovery steps above
   - Verify Account 0 address matches

4. **Confirm**:
   ```bash
   # From Eternl
   ETERNL_ADDR="addr1qyk9mx..."

   # From backup
   BACKUP_ADDR=$(cat wallets.json | jq -r '.[0].address')

   if [ "$ETERNL_ADDR" = "$BACKUP_ADDR" ]; then
       echo "✅ Recovery test PASSED"
   else
       echo "❌ Recovery test FAILED - addresses don't match!"
   fi
   ```

5. **If passed**: Continue mining with confidence

6. **If failed**: Debug before continuing:
   - Check mnemonic copy is correct
   - Verify network (mainnet vs testnet)
   - Check wallet type in Eternl

---

## Recovery Scenarios: Detailed Examples

### Example 1: Server Died, Have Backup

**Situation**: VPS provider shut down server

**What you have**:
```bash
data/s1/backup-20251115-143022/
├── mnemonic.txt
├── wallets.json
├── REPORT.txt
└── ...
```

**Steps**:

1. **Check report**:
   ```bash
   cat data/s1/backup-20251115-143022/REPORT.txt
   ```
   ```
   Wallet 2: Solutions: 1
   Wallet 5: Solutions: 2
   Wallet 7: Solutions: 2
   ```

2. **Get mnemonic**:
   ```bash
   cat data/s1/backup-20251115-143022/mnemonic.txt
   ```

3. **Import to Eternl**: (follow steps above)

4. **In Eternl**:
   - Switch to Account 2 → See NIGHT balance
   - Switch to Account 5 → See NIGHT balance
   - Switch to Account 7 → See NIGHT balance

5. **Total recovered**: 5 solutions worth of NIGHT

**Result**: ✅ All NIGHT recovered, no mining data lost

---

### Example 2: Laptop Died, No Local Backup

**Situation**: Your laptop crashed, lost all local data

**What you have**:
- Mnemonic written on paper (from initial setup)
- No REPORT.txt
- No wallets.json

**Steps**:

1. **Get mnemonic from paper**

2. **Import to Eternl on new device**

3. **Eternl shows**:
   - Account 0 (may or may not have NIGHT)
   - Account 2 (has NIGHT - shows automatically)
   - Account 5 (has NIGHT - shows automatically)
   - Account 7 (has NIGHT - shows automatically)

4. **Check each account** on sm.midnight.gd

5. **Verify balances**

**Result**: ✅ All NIGHT recovered (Eternl auto-discovered accounts with transactions)

---

### Example 3: Multiple Servers, All Down

**Situation**: All 4 VPS servers terminated

**What you have**:
```bash
data/
├── s1/backup-20251115-143022/
├── s2/backup-20251115-143055/
├── s3/backup-20251115-143128/
└── s4/backup-20251115-143201/
```

**Steps**:

1. **Check all reports**:
   ```bash
   cat data/s*/latest/REPORT.txt
   ```

2. **For each server**:
   ```bash
   # Server 1
   cat data/s1/latest/mnemonic.txt
   # Import to Eternl as "Server 1"
   # Note solutions: Wallets 2, 5, 7

   # Server 2
   cat data/s2/latest/mnemonic.txt
   # Import to Eternl as "Server 2"
   # Note solutions: Wallets 1, 3, 6

   # Server 3
   cat data/s3/latest/mnemonic.txt
   # Import to Eternl as "Server 3"
   # Note solutions: Wallets 0, 4, 7

   # Server 4
   cat data/s4/latest/mnemonic.txt
   # Import to Eternl as "Server 4"
   # Note solutions: Wallets 2, 3, 5, 6
   ```

3. **In Eternl**: 4 wallets, each with 8 accounts

4. **Switch between wallets and accounts** to access all NIGHT

**Result**: ✅ All servers' NIGHT recovered

---

## Summary

### Key Takeaways

1. **Mnemonic = Everything**: 24 words recover all wallets
2. **Account N = Wallet N**: Eternl Account 0 is Miner Wallet 0
3. **Check REPORT.txt**: Tells you which accounts have NIGHT
4. **Eternl auto-discovers**: Accounts with transactions show automatically
5. **Test early**: Verify recovery works before mining ends

### Recovery Checklist

**Preparation**:
- [ ] Mnemonic backed up in multiple secure locations
- [ ] REPORT.txt generated with every backup
- [ ] Recovery tested with test import

**When Needed**:
- [ ] Get mnemonic from backup
- [ ] Install Eternl on secure device
- [ ] Restore wallet with 24 words
- [ ] Verify Account 0 address matches backup
- [ ] Check accounts with solutions (per REPORT.txt)
- [ ] Verify balances on sm.midnight.gd
- [ ] Send NIGHT to final destination (when ready)

### Final Advice

**Your mnemonic is precious**:
- Guard it like the valuable secret it is
- Multiple backups in secure locations
- Test recovery before you need it
- Never share with anyone

**Recovery is simple**:
- 24 words → Eternl → All accounts → All NIGHT
- No complex process
- Standard BIP39/CIP-1852
- Works in any compatible wallet

**You control your crypto**:
- No company can freeze your wallet
- No forgot password → lost forever
- No customer support needed
- You are the bank

**But with great power comes great responsibility**:
- Lose mnemonic = Lose NIGHT forever
- No recovery without those 24 words
- Backup, backup, backup!

**Mine confidently knowing you can always recover!**
