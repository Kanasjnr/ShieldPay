use common::poseidon_utils::compute_deposit_commitment;

/// Proves the depositor knows the secret key and the public commitment
/// matches the shielded note they are creating.
pub fn verify_deposit(
    secret_key: Field,
    amount: Field,
    blinding: Field,
    commitment: Field,
) {
    let computed = compute_deposit_commitment(secret_key, amount, blinding);
    assert(computed == commitment, "Invalid deposit commitment");
}