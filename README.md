# Stellar Shield Wallet

Stellar Shield Wallet is a private-by-default, Venmo-like web wallet for USDC on the Stellar network. It utilizes zero-knowledge proofs (zk-SNARKs) to shield transaction amounts and sender/receiver addresses, while preserving a compliance path via Auditor View Keys.

## Architecture
- `/circuits` - Noir ZK circuits (deposit, transfer, withdraw)
- `/contracts` - Soroban Shield Pool smart contract
- `/frontend` - React/Vite dashboard web application (coming soon)

## Development

```bash
# ZK circuits (28 tests)
cd circuits && nargo test

# Soroban contracts (11 tests)
cd contracts && cargo test -p shield-pool
```
