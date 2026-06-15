mod fixtures;
mod transfer;
mod tests;

use transfer::verify_shielded_transfer;

fn main(
    secret_key: Field,
    input_value: Field,
    input_blinding: Field,
    merkle_path: [Field; 8],
    merkle_indices: [bool; 8],
    output_value: Field,
    output_blinding: Field,
    recipient_pubkey: Field,
    merkle_root: pub Field,
    nullifier: pub Field,
    output_commitment: pub Field,
) {
    verify_shielded_transfer(
        secret_key,
        input_value,
        input_blinding,
        merkle_path,
        merkle_indices,
        output_value,
        output_blinding,
        recipient_pubkey,
        merkle_root,
        nullifier,
        output_commitment,
    );
}
