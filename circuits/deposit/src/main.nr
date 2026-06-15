mod deposit;
mod fixtures;
mod tests;

use deposit::verify_deposit;

fn main(
    secret_key: Field,
    amount: Field,
    blinding: Field,
    commitment: pub Field,
) {
    verify_deposit(secret_key, amount, blinding, commitment);
}
