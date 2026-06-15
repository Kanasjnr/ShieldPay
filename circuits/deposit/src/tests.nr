use common::poseidon_utils::compute_deposit_commitment;
use crate::deposit::verify_deposit;
use crate::fixtures::{sample_commitment, TEST_AMOUNT, TEST_BLINDING, TEST_SECRET};

#[test]
fn test_valid_deposit_commitment() {
    verify_deposit(TEST_SECRET, TEST_AMOUNT, TEST_BLINDING, sample_commitment());
}

#[test(should_fail_with = "Invalid deposit commitment")]
fn test_rejects_wrong_commitment() {
    verify_deposit(TEST_SECRET, TEST_AMOUNT, TEST_BLINDING, 0);
}

#[test(should_fail_with = "Invalid deposit commitment")]
fn test_rejects_wrong_amount() {
    verify_deposit(TEST_SECRET, TEST_AMOUNT + 1, TEST_BLINDING, sample_commitment());
}

#[test(should_fail_with = "Invalid deposit commitment")]
fn test_rejects_wrong_blinding() {
    verify_deposit(TEST_SECRET, TEST_AMOUNT, TEST_BLINDING + 1, sample_commitment());
}

#[test(should_fail_with = "Invalid deposit commitment")]
fn test_rejects_wrong_secret() {
    verify_deposit(TEST_SECRET + 1, TEST_AMOUNT, TEST_BLINDING, sample_commitment());
}

#[test]
fn test_zero_amount_deposit() {
    let commitment = compute_deposit_commitment(TEST_SECRET, 0, TEST_BLINDING);
    verify_deposit(TEST_SECRET, 0, TEST_BLINDING, commitment);
}
