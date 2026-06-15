use common::poseidon_utils::compute_deposit_commitment;

pub global TEST_SECRET: Field = 42;
pub global TEST_AMOUNT: Field = 1000;
pub global TEST_BLINDING: Field = 7;

pub fn sample_commitment() -> Field {
    compute_deposit_commitment(TEST_SECRET, TEST_AMOUNT, TEST_BLINDING)
}
