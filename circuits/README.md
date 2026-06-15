# Noir ZK Circuits

Zero-knowledge circuits for Stellar Shield Wallet private USDC transfers.

## Circuits

| Package | Purpose | Public inputs |
|---------|---------|---------------|
| `deposit` | Prove a valid shielded deposit commitment | `commitment` |
| `transfer` | Prove a private shielded transfer | `merkle_root`, `nullifier`, `output_commitment` |
| `withdraw` | Prove unshielding to a public recipient | `merkle_root`, `nullifier`, `withdraw_amount`, `recipient_hash` |

Shared cryptography lives in `common/` (Poseidon2 hashing + Merkle proofs, depth 8).

## Quick start

```bash
# Run all tests (28 cases across common/deposit/transfer/withdraw)
nargo test

# Compile + generate valid Prover.toml + execute witnesses
./scripts/test-and-prove.sh
```

## Test coverage

- **common** (6): Poseidon determinism, commitment/nullifier uniqueness, Merkle sibling order, bad root rejection
- **deposit** (6): valid commitment, wrong commitment/amount/blinding/secret, zero-amount edge case
- **transfer** (9): happy path, bad Merkle root/path/index, wrong nullifier, inflated value, bad output commitment, wrong secret
- **withdraw** (7): happy path, bad root/nullifier/amount/secret, zero recipient hash

## Proving pipeline

```bash
nargo compile --package transfer
node scripts/compute-public-inputs.mjs   # writes transfer/Prover.toml
nargo execute --package transfer         # generates witness
```

Install [Barretenberg (`bb`)](https://noir-lang.org/docs/how_to/how-to-solidity-verifier) for full proof generation when integrating with Soroban.
