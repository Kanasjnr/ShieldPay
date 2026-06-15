use common::merkle::assert_merkle_membership;
use common::poseidon_utils::{
    compute_commitment, compute_nullifier, derive_pubkey,
};

/// Proves a valid unshielding withdrawal:
/// - Spender owns the input note in the Merkle tree
/// - Nullifier is correct (prevents double-spend)
/// - Withdrawn amount matches the note value
/// - Recipient hash binds the public payout destination
pub fn verify_withdraw(
    secret_key: Field,
    input_value: Field,
    input_blinding: Field,
    merkle_path: [Field; 8],
    merkle_indices: [bool; 8],
    merkle_root: Field,
    nullifier: Field,
    withdraw_amount: Field,
    recipient_hash: Field,
) {
    let sender_pubkey = derive_pubkey(secret_key);
    let input_commitment =
        compute_commitment(sender_pubkey, input_value, input_blinding);

    assert_merkle_membership(input_commitment, merkle_path, merkle_indices, merkle_root);

    let computed_nullifier = compute_nullifier(secret_key, input_commitment);
    assert(computed_nullifier == nullifier, "Invalid nullifier");

    assert(input_value == withdraw_amount, "Withdraw amount mismatch");

    assert(recipient_hash != 0, "Recipient hash must be non-zero");

    let binding = compute_commitment(recipient_hash, withdraw_amount, nullifier);
    assert(binding != 0, "Invalid withdrawal binding");
}