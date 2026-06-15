use common::merkle::compute_merkle_root;
use common::poseidon_utils::{
    compute_commitment, compute_nullifier, derive_pubkey,
};

pub global TEST_SECRET: Field = 42;
pub global TEST_VALUE: Field = 1000;
pub global TEST_BLINDING: Field = 7;
pub global TEST_RECIPIENT_HASH: Field = 0xabc;

pub fn sample_input_commitment() -> Field {
    let pubkey = derive_pubkey(TEST_SECRET);
    compute_commitment(pubkey, TEST_VALUE, TEST_BLINDING)
}

pub fn sample_merkle_path() -> [Field; 8] {
    [0; 8]
}

pub fn sample_merkle_indices() -> [bool; 8] {
    [false; 8]
}

pub fn sample_merkle_root() -> Field {
    compute_merkle_root(
        sample_input_commitment(),
        sample_merkle_path(),
        sample_merkle_indices(),
    )
}

pub fn sample_nullifier() -> Field {
    compute_nullifier(TEST_SECRET, sample_input_commitment())
}
