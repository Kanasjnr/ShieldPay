use crate::fixtures::{
    sample_merkle_indices, sample_merkle_path, sample_merkle_root, sample_nullifier,
    TEST_BLINDING, TEST_RECIPIENT_HASH, TEST_SECRET, TEST_VALUE,
};
use crate::withdraw::verify_withdraw;

#[test]
fn test_valid_withdraw() {
    verify_withdraw(
        TEST_SECRET,
        TEST_VALUE,
        TEST_BLINDING,
        sample_merkle_path(),
        sample_merkle_indices(),
        sample_merkle_root(),
        sample_nullifier(),
        TEST_VALUE,
        TEST_RECIPIENT_HASH,
    );
}

#[test(should_fail_with = "Invalid Merkle membership proof")]
fn test_rejects_invalid_merkle_root() {
    verify_withdraw(
        TEST_SECRET,
        TEST_VALUE,
        TEST_BLINDING,
        sample_merkle_path(),
        sample_merkle_indices(),
        999,
        sample_nullifier(),
        TEST_VALUE,
        TEST_RECIPIENT_HASH,
    );
}

#[test(should_fail_with = "Invalid nullifier")]
fn test_rejects_wrong_nullifier() {
    verify_withdraw(
        TEST_SECRET,
        TEST_VALUE,
        TEST_BLINDING,
        sample_merkle_path(),
        sample_merkle_indices(),
        sample_merkle_root(),
        0,
        TEST_VALUE,
        TEST_RECIPIENT_HASH,
    );
}

#[test(should_fail_with = "Withdraw amount mismatch")]
fn test_rejects_partial_withdraw_amount() {
    verify_withdraw(
        TEST_SECRET,
        TEST_VALUE,
        TEST_BLINDING,
        sample_merkle_path(),
        sample_merkle_indices(),
        sample_merkle_root(),
        sample_nullifier(),
        TEST_VALUE - 1,
        TEST_RECIPIENT_HASH,
    );
}

#[test(should_fail_with = "Withdraw amount mismatch")]
fn test_rejects_inflated_withdraw_amount() {
    verify_withdraw(
        TEST_SECRET,
        TEST_VALUE,
        TEST_BLINDING,
        sample_merkle_path(),
        sample_merkle_indices(),
        sample_merkle_root(),
        sample_nullifier(),
        TEST_VALUE + 1,
        TEST_RECIPIENT_HASH,
    );
}

#[test(should_fail_with = "Invalid Merkle membership proof")]
fn test_rejects_wrong_secret() {
    verify_withdraw(
        TEST_SECRET + 1,
        TEST_VALUE,
        TEST_BLINDING,
        sample_merkle_path(),
        sample_merkle_indices(),
        sample_merkle_root(),
        sample_nullifier(),
        TEST_VALUE,
        TEST_RECIPIENT_HASH,
    );
}

#[test(should_fail_with = "Recipient hash must be non-zero")]
fn test_rejects_zero_recipient_hash() {
    verify_withdraw(
        TEST_SECRET,
        TEST_VALUE,
        TEST_BLINDING,
        sample_merkle_path(),
        sample_merkle_indices(),
        sample_merkle_root(),
        sample_nullifier(),
        TEST_VALUE,
        0,
    );
}
