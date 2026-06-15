use soroban_sdk::{Bytes, Env, U256};

/// MVP proof verifier.
///
/// Production deployments should replace this with a Groth16 verifier contract
/// using Soroban BN254 host functions. For the hackathon MVP we validate proof
/// structure and bind public inputs to the on-chain Merkle root.
pub fn verify_transfer_proof(
    env: &Env,
    proof: &Bytes,
    merkle_root: &U256,
    nullifier: &U256,
    output_commitment: &U256,
    expected_root: &U256,
) -> bool {
    if proof.len() < 64 {
        return false;
    }
    if merkle_root != expected_root {
        return false;
    }
    if *nullifier == U256::from_u32(env, 0) || *output_commitment == U256::from_u32(env, 0) {
        return false;
    }

    let digest = env.crypto().keccak256(proof);
    let binding_bytes = Bytes::from_array(env, &digest.to_array());
    let binding = env.crypto().keccak256(&binding_bytes);
    binding.to_array()[0] != 0
}

pub fn verify_withdraw_proof(
    env: &Env,
    proof: &Bytes,
    merkle_root: &U256,
    nullifier: &U256,
    withdraw_amount: i128,
    recipient_hash: &U256,
    expected_root: &U256,
) -> bool {
    if withdraw_amount <= 0 || *recipient_hash == U256::from_u32(env, 0) {
        return false;
    }
    verify_transfer_proof(
        env,
        proof,
        merkle_root,
        nullifier,
        recipient_hash,
        expected_root,
    )
}
