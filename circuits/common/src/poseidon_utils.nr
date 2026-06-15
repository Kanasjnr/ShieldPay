use poseidon::poseidon2::Poseidon2;

pub fn hash_1(a: Field) -> Field {
    Poseidon2::hash([a], 1)
}

pub fn hash_2(a: Field, b: Field) -> Field {
    Poseidon2::hash([a, b], 2)
}

pub fn hash_3(a: Field, b: Field, c: Field) -> Field {
    Poseidon2::hash([a, b, c], 3)
}

pub fn derive_pubkey(secret_key: Field) -> Field {
    hash_1(secret_key)
}

pub fn compute_commitment(pubkey: Field, value: Field, blinding: Field) -> Field {
    hash_3(pubkey, value, blinding)
}

pub fn compute_nullifier(secret_key: Field, commitment: Field) -> Field {
    hash_2(secret_key, commitment)
}

pub fn compute_deposit_commitment(secret_key: Field, amount: Field, blinding: Field) -> Field {
    let pubkey = derive_pubkey(secret_key);
    compute_commitment(pubkey, amount, blinding)
}

#[test]
fn test_pubkey_derivation_is_deterministic() {
    let secret = 42;
    assert(derive_pubkey(secret) == derive_pubkey(secret));
}

#[test]
fn test_commitment_changes_with_blinding() {
    let pubkey = derive_pubkey(42);
    let c1 = compute_commitment(pubkey, 1000, 7);
    let c2 = compute_commitment(pubkey, 1000, 8);
    assert(c1 != c2);
}

#[test]
fn test_nullifier_unique_per_commitment() {
    let secret = 42;
    let c1 = compute_deposit_commitment(secret, 1000, 7);
    let c2 = compute_deposit_commitment(secret, 1000, 8);
    let n1 = compute_nullifier(secret, c1);
    let n2 = compute_nullifier(secret, c2);
    assert(n1 != n2);
}
