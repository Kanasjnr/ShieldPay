use soroban_poseidon::poseidon2_hash;
use soroban_sdk::{crypto::bn254::Fr as Bn254Fr, vec, Env, U256};

pub const MERKLE_DEPTH: u32 = 8;

pub fn hash_1(env: &Env, value: &U256) -> U256 {
    let inputs = vec![env, value.clone()];
    poseidon2_hash::<2, Bn254Fr>(env, &inputs)
}

pub fn hash_2(env: &Env, left: &U256, right: &U256) -> U256 {
    let inputs = vec![env, left.clone(), right.clone()];
    poseidon2_hash::<3, Bn254Fr>(env, &inputs)
}

pub fn hash_3(env: &Env, a: &U256, b: &U256, c: &U256) -> U256 {
    let inputs = vec![env, a.clone(), b.clone(), c.clone()];
    poseidon2_hash::<4, Bn254Fr>(env, &inputs)
}

pub fn u256_from_u32(env: &Env, value: u32) -> U256 {
    U256::from_u32(env, value)
}

pub fn zero_hash(env: &Env) -> U256 {
    u256_from_u32(env, 0)
}

pub fn compute_merkle_root(env: &Env, leaf: &U256, path: &[U256], indices: &[bool]) -> U256 {
    let mut current = leaf.clone();
    for i in 0..MERKLE_DEPTH as usize {
        if indices[i] {
            current = hash_2(env, &path[i], &current);
        } else {
            current = hash_2(env, &current, &path[i]);
        }
    }
    current
}

pub fn zero_array(env: &Env) -> [U256; MERKLE_DEPTH as usize] {
    core::array::from_fn(|_| zero_hash(env))
}
