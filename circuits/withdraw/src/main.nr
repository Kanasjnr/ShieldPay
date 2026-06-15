mod fixtures;
mod tests;
mod withdraw;

use withdraw::verify_withdraw;

fn main(
    secret_key: Field,
    input_value: Field,
    input_blinding: Field,
    merkle_path: [Field; 8],
    merkle_indices: [bool; 8],
    merkle_root: pub Field,
    nullifier: pub Field,
    withdraw_amount: pub Field,
    recipient_hash: pub Field,
) {
    verify_withdraw(
        secret_key,
        input_value,
        input_blinding,
        merkle_path,
        merkle_indices,
        merkle_root,
        nullifier,
        withdraw_amount,
        recipient_hash,
    );
}
