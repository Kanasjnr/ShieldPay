use common::merkle::assert_merkle_membership;
use common::poseidon_utils::{
    compute_commitment, compute_nullifier, derive_pubkey,
};

/// Proves a valid shielded spend:
/// - Sender knows the secret key for the input note
/// - Input note is a leaf in the Merkle tree
/// - Input value equals output value (no inflation)
/// - Nullifier is correctly derived to prevent double-spend
pub fn verify_shielded_transfer(
    secret_key: Field,
    input_value: Field,
    input_blinding: Field,
    merkle_path: [Field; 8],
    merkle_indices: [bool; 8],
    output_value: Field,
    output_blinding: Field,
    recipient_pubkey: Field,
    merkle_root: Field,
    nullifier: Field,
    output_commitment: Field,
) {
    let sender_pubkey = derive_pubkey(secret_key);
    let input_commitment =
        compute_commitment(sender_pubkey, input_value, input_blinding);

    assert_merkle_membership(input_commitment, merkle_path, merkle_indices, merkle_root);

    let computed_nullifier = compute_nullifier(secret_key, input_commitment);
    assert(computed_nullifier == nullifier, "Invalid nullifier");

    assert(input_value == output_value, "Value conservation violated");

    let computed_output =
        compute_commitment(recipient_pubkey, output_value, output_blinding);
    assert(computed_output == output_commitment, "Invalid output commitment");
}
