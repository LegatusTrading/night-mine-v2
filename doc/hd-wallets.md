# HD Wallets: Complete Guide

This document explains Hierarchical Deterministic (HD) wallets, how they work in Midnight Miner, and why they're used.

---

## What is an HD Wallet?

**Hierarchical Deterministic (HD) Wallet**: A wallet system where one master seed generates unlimited child wallets following a deterministic (predictable, reproducible) hierarchy.

### Key Concept

```
ONE master seed (24 words)
  ↓
INFINITE derived wallets (accounts)
```

**Property**: Anyone with the master seed can derive the exact same wallets in the same order.

---

## Why HD Wallets?

### Problem with Random Wallets (Old Approach)

**Old midnight-miner**:
```python
# Each wallet had its own random mnemonic
wallets = []
for i in range(16):
    mnemonic = generate_random_15_words()  # Different every time!
    wallet = create_from_mnemonic(mnemonic)
    wallets.append({
        "mnemonic": mnemonic,
        "address": wallet.address
    })
```

**Result**: `wallets.json` contains 16 different mnemonics
```json
[
  {
    "mnemonic": "zoo disorder large athlete senior...",
    "address": "addr1vxulucnv..."
  },
  {
    "mnemonic": "rapid glove donate entire assume...",
    "address": "addr1v8tkljlh..."
  },
  ... // 14 more, each with different mnemonic
]
```

**Problems**:
1. **16 backups needed**: Must save all 16 mnemonics
2. **Hard to recover**: Import each mnemonic separately in Eternl
3. **Easy to lose**: If one mnemonic lost, that wallet's NIGHT is gone forever
4. **Not standard**: Wallets not related to each other

---

### Solution: HD Wallets (New Approach)

**Midnight Miner v2**:
```bash
# Generate ONE master seed
./generate-hd-wallet.sh --accounts 16 --output hd-wallets

# Derives 16 wallets from that seed
./import-hd-wallets.py hd-wallets 16
```

**Result**: `hd-wallets/mnemonic.txt` contains ONE 24-word seed
```
rare energy visit fire ready surge gate around usage any elegant piano
gaze multiply moment rule guard busy material biology gentle saddle caught knife
```

**Wallets derived**:
```
m/1852'/1815'/0'  → Wallet 0: addr1qyk9mx...
m/1852'/1815'/1'  → Wallet 1: addr1qxvx84...
m/1852'/1815'/2'  → Wallet 2: addr1qyncsq...
... // 13 more, all from SAME master seed
```

**Benefits**:
1. **One backup**: 24 words recover ALL wallets
2. **Easy recovery**: Eternl shows all accounts automatically
3. **Standard**: BIP39/CIP-1852 (works in any Cardano wallet)
4. **Infinite accounts**: Can derive account 17, 18, 19... later

---

## HD Wallet Standards

### BIP39: Mnemonic Generation

**BIP = Bitcoin Improvement Proposal** (adopted by many cryptocurrencies)

**BIP39 defines**:
- How to generate mnemonic from entropy
- Word list (2048 words)
- Checksum calculation
- Mnemonic → seed conversion

**Example**:
```
Entropy (256 bits random) → 24-word mnemonic
Mnemonic → Seed (512 bits via PBKDF2)
```

**Our mnemonic** (24 words = 256 bits entropy + 8 bits checksum):
```
rare energy visit fire ready surge gate around usage any elegant piano
gaze multiply moment rule guard busy material biology gentle saddle caught knife
```

---

### CIP-1852: Cardano HD Wallets

**CIP = Cardano Improvement Proposal**

**CIP-1852 defines**:
- Derivation path for Cardano wallets
- How to derive payment and stake keys
- Address construction from keys

**Derivation Path**:
```
m / purpose' / coin_type' / account' / role / index

m / 1852' / 1815' / 0' / 0 / 0
│    │       │      │    │   │
│    │       │      │    │   └─ Address index (0 for first)
│    │       │      │    └───── Role (0=payment, 2=stake)
│    │       │      └────────── Account number (0, 1, 2, ...)
│    │       └───────────────── Coin type (1815 = ADA)
│    └───────────────────────── Purpose (1852 = HD wallet)
└────────────────────────────── Master key
```

**Apostrophe (')** = Hardened derivation (more secure, can't derive child from parent public key)

---

### Our Derivation

**For each account N (wallet N)**:

```
Payment key path: m/1852'/1815'/N'/0/0
Stake key path:   m/1852'/1815'/N'/2/0
```

**Account 0**:
- Payment: m/1852'/1815'/0'/0/0
- Stake: m/1852'/1815'/0'/2/0
- Address: addr1q... (base address with both keys)

**Account 1**:
- Payment: m/1852'/1815'/1'/0/0
- Stake: m/1852'/1815'/1'/2/0
- Address: addr1q... (different address)

**Account 2**:
- Payment: m/1852'/1815'/2'/0/0
- Stake: m/1852'/1815'/2'/2/0
- Address: addr1q... (different address)

---

## How HD Wallet Generation Works

### Step 1: Generate Master Seed

**Script**: `generate-hd-wallet.sh`

**Uses**: Cardano CLI tools

```bash
# Generate 24-word mnemonic
cardano-address recovery-phrase generate --size 24 > mnemonic.txt

# Content:
rare energy visit fire ready surge gate around usage any elegant piano
gaze multiply moment rule guard busy material biology gentle saddle caught knife
```

**This is the ONLY secret you need to backup!**

---

### Step 2: Derive Root Key

```bash
# Mnemonic → Root extended private key
cat mnemonic.txt | cardano-address key from-recovery-phrase Shelley > root.prv

# Root key (extended private key)
# Contains: private key + chain code (for deriving children)
```

---

### Step 3: Derive Account Keys

**For account 0**:

```bash
# Account key
cat root.prv | cardano-address key child 1852H/1815H/0H > account-0.prv

# Payment key (role 0, index 0)
cat account-0.prv | cardano-address key child 0/0 > account-0/payment/0/payment.skey

# Stake key (role 2, index 0)
cat account-0.prv | cardano-address key child 2/0 > account-0/stake/stake.skey
```

**Repeat for accounts 1, 2, 3, ..., N**

---

### Step 4: Derive Public Keys

```bash
# Payment public key
cat account-0/payment/0/payment.skey | cardano-address key public --with-chain-code > payment.pub

# Stake public key
cat account-0/stake/stake.skey | cardano-address key public --with-chain-code > stake.pub
```

---

### Step 5: Create Address

```bash
# Payment verification key hash
payment_vkh=$(cat payment.pub | cardano-address key hash)

# Stake verification key hash
stake_vkh=$(cat stake.pub | cardano-address key hash)

# Build base address (payment + stake)
cardano-address address payment \
    --network-tag mainnet \
    --payment-verification-key-hash $payment_vkh \
    --stake-verification-key-hash $stake_vkh \
    > address.txt

# Result: addr1qyk9mx70qmpxwd0vn9tv3lgthfls9e...
```

**Key**: Including both payment and stake hashes creates **base address** (addr1q...)

---

## Base vs Enterprise Addresses

### Base Address (addr1q...)

**Structure**:
```
addr1q + payment_key_hash + stake_key_hash
```

**Uses**:
- Payment: Receiving and sending funds
- Staking: Participating in staking rewards

**Compatibility**:
- ✅ Eternl wallet
- ✅ Nufi wallet
- ✅ Daedalus wallet
- ✅ sm.midnight.gd
- ✅ All Cardano dApps

**This is what we use!**

---

### Enterprise Address (addr1v...)

**Structure**:
```
addr1v + payment_key_hash
```

**Uses**:
- Payment only (no staking)
- Used by exchanges, contracts

**Compatibility**:
- ❌ Eternl (shows wrong address)
- ❌ Nufi (shows wrong address)
- ❌ sm.midnight.gd (rejects as invalid)

**We don't use these!**

---

### Why Base Addresses Matter

**Old miner** created enterprise addresses:
```python
# Only payment key, no stake key
address = Address(
    payment_part=payment_key_hash,
    # No staking_part!
    network=Network.MAINNET
)
# Result: addr1v... (enterprise)
```

**Problem**: Can't verify on sm.midnight.gd, Eternl shows different address

**New miner** creates base addresses:
```python
# Both payment and stake keys
address = Address(
    payment_part=payment_key_hash,
    staking_part=stake_key_hash,  # Include this!
    network=Network.MAINNET
)
# Result: addr1q... (base)
```

**Solution**: Works everywhere, Eternl shows exact same address

---

## Import to Miner Format

### Script: `import-hd-wallets.py`

**Purpose**: Convert HD wallet keys to format miner.py expects

**Input**: HD wallet directory structure
```
hd-wallets/
├── mnemonic.txt
└── account-{N}/
    ├── payment/0/payment.skey
    └── stake/stake.skey
```

**Output**: `wallets.json`
```json
[
  {
    "address": "addr1qyk9mx70qmpxwd0vn9tv3lgthfls9e...",
    "pubkey": "b8df1368c649e4fa9bbff61057f95a270...",
    "signature": "84584da30127676164647265737358..."
  },
  ... // More wallets
]
```

---

### Import Process

```python
def derive_wallet_from_hd_files(hd_wallet_dir, account_num):
    # Load signing keys
    payment_skey = load_extended_signing_key(
        f"{hd_wallet_dir}/account-{account_num}/payment/0/payment.skey"
    )
    stake_skey = load_stake_signing_key(
        f"{hd_wallet_dir}/account-{account_num}/stake/stake.skey"
    )

    # Derive verification keys (public keys)
    payment_vkey = payment_skey.to_verification_key()
    stake_vkey = stake_skey.to_verification_key()

    # Create BASE address
    address = Address(
        payment_part=payment_vkey.hash(),
        staking_part=stake_vkey.hash(),  # IMPORTANT!
        network=Network.MAINNET
    )

    # Sign terms & conditions
    terms = build_terms_and_conditions()
    signature = payment_skey.sign(terms)

    return {
        "address": str(address),
        "pubkey": payment_vkey.to_cbor().hex(),
        "signature": signature.to_cbor().hex()
    }
```

**Key Line**: `staking_part=stake_vkey.hash()` → Creates base address

---

## Recovery in Eternl

### Import Process

1. **Open Eternl** → "Restore Wallet"
2. **Select**: "Cardano" network
3. **Choose**: "24 words" recovery phrase
4. **Enter mnemonic**:
   ```
   rare energy visit fire ready surge gate around usage any elegant piano
   gaze multiply moment rule guard busy material biology gentle saddle caught knife
   ```
5. **Set wallet name**: e.g., "Mining Server 1"
6. **Set spending password**: (your choice)
7. **Click "Restore"**

---

### What Eternl Does

Internally, Eternl follows the same CIP-1852 derivation:

```
For account 0:
  m/1852'/1815'/0'/0/0 → Payment key
  m/1852'/1815'/0'/2/0 → Stake key
  Payment hash + Stake hash → addr1qyk9mx...

For account 1:
  m/1852'/1815'/1'/0/0 → Payment key
  m/1852'/1815'/1'/2/0 → Stake key
  Payment hash + Stake hash → addr1qxvx84...

... (continues for all accounts)
```

**Result**: Eternl shows all accounts automatically!

---

### Switching Between Accounts

**In Eternl**:
1. Click wallet name at top
2. See list: "Account 0", "Account 1", "Account 2", ...
3. Click any account to switch to it
4. See that account's address and balance

**Mapping**:
- Eternl "Account 0" = Miner "Wallet 0"
- Eternl "Account 1" = Miner "Wallet 1"
- Eternl "Account 2" = Miner "Wallet 2"

**If backup report says**:
```
Wallet 2: 1 solution
Wallet 5: 2 solutions
Wallet 7: 2 solutions
```

**Then in Eternl**:
- Switch to Account 2 → See NIGHT balance
- Switch to Account 5 → See NIGHT balance
- Switch to Account 7 → See NIGHT balance

---

## HD Wallet File Structure

### Generated by `generate-hd-wallet.sh`

```
hd-wallets/
├── mnemonic.txt                           # 24-word seed (CRITICAL!)
├── root.prv                               # Root extended private key
├── account-0/
│   ├── payment/
│   │   └── 0/
│   │       ├── payment.skey              # Payment signing key
│   │       └── payment.pub               # Payment public key
│   └── stake/
│       ├── stake.skey                     # Stake signing key
│       └── stake.pub                      # Stake public key
├── account-1/
│   └── ... (same structure)
└── account-N/
    └── ... (same structure)
```

### Key Files

**mnemonic.txt**:
```
rare energy visit fire ready surge gate around usage any elegant piano
gaze multiply moment rule guard busy material biology gentle saddle caught knife
```
- **Purpose**: Master seed, recovers everything
- **Backup**: YES! Multiple copies, secure storage
- **Share**: NEVER!

**root.prv**:
```
root_xsk1... (long hex string)
```
- **Purpose**: Root extended private key (derived from mnemonic)
- **Backup**: Optional (can regenerate from mnemonic)
- **Share**: NEVER!

**payment.skey** (per account):
```json
{
  "type": "PaymentExtendedSigningKeyShelley_ed25519_bip32",
  "description": "Payment Signing Key",
  "cborHex": "5880..."
}
```
- **Purpose**: Sign transactions for this account
- **Backup**: Optional (can regenerate from mnemonic)
- **Share**: NEVER!

**stake.skey** (per account):
```json
{
  "type": "StakeExtendedSigningKeyShelley_ed25519_bip32",
  "description": "Stake Signing Key",
  "cborHex": "5880..."
}
```
- **Purpose**: Sign staking operations for this account
- **Backup**: Optional (can regenerate from mnemonic)
- **Share**: NEVER!

---

## Security Model

### Hierarchical Key Derivation

```
Master Seed (mnemonic)
  ↓ [CANNOT reverse]
Root Private Key
  ↓ [CANNOT reverse]
Account 0 Private Key
  ↓ [CANNOT reverse]
Payment Private Key → Public Key → Address
```

**Property**: Can derive child from parent, but NOT parent from child

**Security**:
- Knowing one account's private key → Can't derive master seed
- Knowing one account's private key → Can't derive other accounts
- Knowing master seed → Can derive ALL accounts

**Therefore**: Protect the mnemonic above all else!

---

### What to Backup

**Essential**:
- ✅ mnemonic.txt (24 words)

**Optional**:
- ⚠️ wallets.json (convenience, can regenerate)
- ⚠️ HD wallet keys (can regenerate from mnemonic)

**Why mnemonic is enough**:
1. Mnemonic → Root key (deterministic)
2. Root key → Account keys (deterministic)
3. Account keys → Addresses (deterministic)

**Same mnemonic = Same addresses every time**

---

## Verification

### Test HD Wallet Recovery

**Before mining, test recovery**:

1. **Generate wallet**:
   ```bash
   ./generate-hd-wallet.sh --accounts 4 --output test-hd
   ```

2. **Save mnemonic**:
   ```bash
   cp test-hd/mnemonic.txt ~/backup/test-mnemonic.txt
   ```

3. **Import to miner**:
   ```bash
   python3 import-hd-wallets.py test-hd 4
   cat wallets.json  # Note first address
   ```

4. **Import to Eternl**:
   - Restore with 24 words
   - Check Account 0 address

5. **Verify match**:
   ```bash
   # Should be identical:
   cat wallets.json | jq '.[0].address'  # From miner
   # vs Eternl Account 0 receive address
   ```

**If they match**: HD wallet is working correctly!

---

## Common Questions

### Can I use the same mnemonic on multiple machines?

**Yes, but use different account ranges!**

Example:
```
Machine 1: Accounts 0-15  (16 wallets)
Machine 2: Accounts 16-31 (16 wallets)
Machine 3: Accounts 32-47 (16 wallets)
```

**Benefit**: ONE mnemonic backs up ALL machines!

**How**:
```bash
# Machine 1
./generate-hd-wallet.sh --accounts 16 --account-offset 0

# Machine 2 (start from account 16)
./generate-hd-wallet.sh --accounts 16 --account-offset 16

# Machine 3 (start from account 32)
./generate-hd-wallet.sh --accounts 16 --account-offset 32
```

---

### How many accounts can I derive?

**Theoretically**: 2^31 accounts (over 2 billion)

**Practically**: Unlimited for our purposes

**Eternl**: Will discover and show all accounts with transactions

---

### What if I lose wallets.json but have mnemonic?

**No problem!** Regenerate:

```bash
# Regenerate HD wallet from mnemonic
./generate-hd-wallet.sh --accounts 8 --output hd-wallets
# (Uses existing mnemonic if present)

# Re-import
python3 import-hd-wallets.py hd-wallets 8

# wallets.json recreated with SAME addresses!
```

---

### What if I lose mnemonic?

**Cannot recover!**

- Mnemonic is the master key
- No mnemonic = No access to wallets
- No way to derive accounts without it

**This is why we**:
- Backup immediately after generation
- Backup with every stop
- Show mnemonic to user during setup
- Recommend multiple backup locations

---

## Summary

### HD Wallets Give Us

1. **One backup**: 24 words secure all wallets
2. **Standard recovery**: Works in any Cardano wallet
3. **Easy verification**: Eternl shows all accounts automatically
4. **Base addresses**: Compatible with sm.midnight.gd
5. **Infinite expansion**: Can always derive more accounts

### Key Takeaways

- **BIP39**: Mnemonic standard
- **CIP-1852**: Cardano derivation paths
- **m/1852'/1815'/N'/0/0**: Payment key for account N
- **m/1852'/1815'/N'/2/0**: Stake key for account N
- **Base address**: Payment hash + Stake hash
- **Eternl Account N**: Same as Miner Wallet N
- **Backup mnemonic**: Recovers everything

**Protect your mnemonic = Protect your NIGHT!**
