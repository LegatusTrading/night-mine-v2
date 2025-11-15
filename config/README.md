# Configuration Files

## Setup

1. Copy the example files and remove the `.example` extension:
   ```bash
   cp local.conf.example local.conf
   cp s1.conf.example s1.conf
   ```

2. Edit each config file with your specific settings

3. For additional servers, copy s1.conf to s2.conf, s3.conf, etc.

## Configuration Variables

- **WORKERS**: Number of mining workers (CPU cores to use)
- **WALLETS**: Number of wallets to create (typically same as WORKERS or 2x)
- **NETWORK**: `mainnet` or `testnet`
- **DATA_DIR**: Local directory for backups (ALWAYS a path on your local machine)
- **SSH_HOST**: SSH connection string for remote servers (e.g., `root@IP_ADDRESS`)
- **REMOTE_DIR**: Directory on remote server where miner runs (e.g., `/root/miner`)

## Important Notes

- **DATA_DIR is always local**: Even for remote mining, backups are downloaded to your local machine
- **One config per machine**: Create separate configs for each server (local.conf, s1.conf, s2.conf, etc.)
- **Config naming**: The config filename determines the host identifier used in commands
  - `local.conf` → `./mine setup` (local)
  - `s1.conf` → `./mine setup-s1` (remote)
  - `s2.conf` → `./mine setup-s2` (remote)
