# Soroban Contracts

Stellar Shield Wallet on-chain components.

## Shield Pool (`contracts/shield-pool`)

Escrows public USDC, tracks shielded commitments in a Poseidon2 Merkle tree (depth 8), and prevents double-spends via nullifiers.

### Functions

| Function | Description |
|----------|-------------|
| `initialize(admin, token)` | Bind admin + USDC token address |
| `deposit(from, amount, commitment)` | Pull public USDC, append commitment leaf |
| `transfer(proof, merkle_root, nullifier, output_commitment)` | Verify transfer proof, spend nullifier, append output |
| `withdraw(proof, merkle_root, nullifier, amount, recipient, recipient_hash)` | Verify withdraw proof, spend nullifier, pay recipient |
| `get_root()` / `get_next_index()` / `is_nullifier_used()` | Read pool state |

### Development

```bash
cd contracts
cargo test -p shield-pool
stellar contract build --package shield-pool
```

### Proof verification (MVP)

The on-chain verifier checks proof structure and binds public inputs to the live Merkle root. Replace with a Groth16 BN254 verifier for production.
