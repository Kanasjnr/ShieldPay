# Stellar Shield Wallet

Stellar Shield Wallet is a private-by-default, Venmo-like web wallet for USDC on the Stellar network. It utilizes zero-knowledge proofs (zk-SNARKs) to shield transaction amounts and sender/receiver addresses, while preserving a compliance path via Auditor View Keys.

## Architecture
- `/circuits` - Noir ZK circuits.
- `/contracts` - Soroban smart contracts (Rust).
- `/frontend` - React/Vite dashboard web application.
