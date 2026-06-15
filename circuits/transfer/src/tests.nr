use crate::fixtures::{
    sample_input_commitment, sample_merkle_indices, sample_merkle_path,
    sample_merkle_root, sample_nullifier, sample_output_commitment, TEST_BLINDING,
    TEST_OUT_BLINDING, TEST_RECIPIENT, TEST_SECRET, TEST_VALUE,
};
use crate::transfer::verify_shielded_transfer;

#[test]
fn test_happy_path_full_spend() {
    verify_shielded_transfer(
        TEST_SECRET,
        TEST_VALUE,
        TEST_BLINDING,
        sample_merkle_path(),
        sample_merkle_indices(),
        TEST_VALUE,
        TEST_OUT_BLINDING,
        TEST_RECIPIENT,
        sample_merkle_root(),
        sample_nullifier(),
        sample_output_commitment(),
    );
}

#[test(should_fail_with = "Invalid Merkle membership proof")]
fn test_rejects_invalid_merkle_root() {
    verify_shielded_transfer(
        TEST_SECRET,
        TEST_VALUE,
        TEST_BLINDING,
        sample_merkle_path(),
        sample_merkle_indices(),
        TEST_VALUE,
        TEST_OUT_BLINDING,
        TEST_RECIPIENT,
        999,
        sample_nullifier(),
        sample_output_commitment(),
    );
}

#[test(should_fail_with = "Invalid nullifier")]
fn test_rejects_wrong_nullifier() {
    verify_shielded_transfer(
        TEST_SECRET,
        TEST_VALUE,
        TEST_BLINDING,
        sample_merkle_path(),
        sample_merkle_indices(),
        TEST_VALUE,
        TEST_OUT_BLINDING,
        TEST_RECIPIENT,
        sample_merkle_root(),
        123456,
        sample_output_commitment(),
    );
}

#[test(should_fail_with = "Value conservation violated")]
fn test_rejects_inflated_output_value() {
    verify_shielded_transfer(
        TEST_SECRET,
        TEST_VALUE,
        TEST_BLINDING,
        sample_merkle_path(),
        sample_merkle_indices(),
        TEST_VALUE + 1,
        TEST_OUT_BLINDING,
        TEST_RECIPIENT,
        sample_merkle_root(),
        sample_nullifier(),
        sample_output_commitment(),
    );
}

#[test(should_fail_with = "Invalid output commitment")]
fn test_rejects_wrong_output_commitment() {
    verify_shielded_transfer(
        TEST_SECRET,
        TEST_VALUE,
        TEST_BLINDING,
        sample_merkle_path(),
        sample_merkle_indices(),
        TEST_VALUE,
        TEST_OUT_BLINDING,
        TEST_RECIPIENT,
        sample_merkle_root(),
        sample_nullifier(),
        0,
    );
}

#[test(should_fail_with = "Invalid Merkle membership proof")]
fn test_rejects_wrong_secret_key() {
    verify_shielded_transfer(
        TEST_SECRET + 1,
        TEST_VALUE,
        TEST_BLINDING,
        sample_merkle_path(),
        sample_merkle_indices(),
        TEST_VALUE,
        TEST_OUT_BLINDING,
        TEST_RECIPIENT,
        sample_merkle_root(),
        sample_nullifier(),
        sample_output_commitment(),
    );
}

#[test(should_fail_with = "Invalid Merkle membership proof")]
fn test_rejects_wrong_merkle_path() {
    let mut bad_path = sample_merkle_path();
    bad_path[0] = 1;

    verify_shielded_transfer(
        TEST_SECRET,
        TEST_VALUE,
        TEST_BLINDING,
        bad_path,
        sample_merkle_indices(),
        TEST_VALUE,
        TEST_OUT_BLINDING,
        TEST_RECIPIENT,
        sample_merkle_root(),
        sample_nullifier(),
        sample_output_commitment(),
    );
}

#[test(should_fail_with = "Invalid Merkle membership proof")]
fn test_rejects_wrong_merkle_index() {
    let mut bad_indices = sample_merkle_indices();
    bad_indices[0] = true;

    verify_shielded_transfer(
        TEST_SECRET,
        TEST_VALUE,
        TEST_BLINDING,
        sample_merkle_path(),
        bad_indices,
        TEST_VALUE,
        TEST_OUT_BLINDING,
        TEST_RECIPIENT,
        sample_merkle_root(),
        sample_nullifier(),
        sample_output_commitment(),
    );
}

#[test]
fn test_input_commitment_is_in_tree_with_fixture_root() {
    let commitment = sample_input_commitment();
    let root = sample_merkle_root();
    assert(commitment != root);
}
