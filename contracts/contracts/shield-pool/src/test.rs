#![cfg(test)]

use super::*;
use crate::crypto_util::{compute_merkle_root, hash_1, hash_2, hash_3, zero_array, zero_hash};
use soroban_sdk::{testutils::Address as _, token::StellarAssetClient, Address, Bytes, Env, U256};
use soroban_sdk::token::TokenClient;

fn setup() -> (Env, Address, Address, Address, ShieldPoolClient<'static>) {
    let env = Env::default();
    env.mock_all_auths();

    let admin = Address::generate(&env);
    let depositor = Address::generate(&env);
    let recipient = Address::generate(&env);

    let sac = env.register_stellar_asset_contract_v2(admin.clone());
    let token = sac.address();
    let contract_id = env.register(ShieldPool, ());
    let client = ShieldPoolClient::new(&env, &contract_id);

    client.initialize(&admin, &token);

    let token_admin = StellarAssetClient::new(&env, &token);
    token_admin.mint(&depositor, &10_000);

    (env, depositor, recipient, contract_id, client)
}

fn sample_commitment(env: &Env) -> U256 {
    let secret = U256::from_u32(env, 42);
    let pubkey = hash_1(env, &secret);
    hash_3(
        env,
        &pubkey,
        &U256::from_u32(env, 1000),
        &U256::from_u32(env, 7),
    )
}

fn sample_nullifier(env: &Env, commitment: &U256) -> U256 {
    hash_2(env, &U256::from_u32(env, 42), commitment)
}

fn sample_output_commitment(env: &Env) -> U256 {
    hash_3(
        env,
        &U256::from_u32(env, 99),
        &U256::from_u32(env, 1000),
        &U256::from_u32(env, 13),
    )
}

fn mock_proof(env: &Env) -> Bytes {
    let mut proof = Bytes::new(env);
    for i in 0u8..64 {
        proof.push_back(i);
    }
    proof
}

#[test]
fn test_initialize_sets_empty_root() {
    let env = Env::default();
    let admin = Address::generate(&env);
    let sac = env.register_stellar_asset_contract_v2(admin.clone());
    let contract_id = env.register(ShieldPool, ());
    let client = ShieldPoolClient::new(&env, &contract_id);
    client.initialize(&admin, &sac.address());

    assert_eq!(client.get_root(), zero_hash(&env));
    assert_eq!(client.get_next_index(), 0);
}

#[test]
fn test_deposit_updates_root_and_index() {
    let (env, depositor, _, _, client) = setup();
    let commitment = sample_commitment(&env);

    let root = client.deposit(&depositor, &1000, &commitment);
    assert_eq!(client.get_root(), root);
    assert_eq!(client.get_next_index(), 1);
}

#[test]
#[should_panic(expected = "Error(Contract, #4)")]
fn test_deposit_rejects_zero_amount() {
    let (env, depositor, _, _, client) = setup();
    let _ = client.deposit(&depositor, &0, &sample_commitment(&env));
}

#[test]
fn test_transfer_spends_nullifier_and_appends_output() {
    let (env, depositor, _, _, client) = setup();
    let commitment = sample_commitment(&env);
    let root_after_deposit = client.deposit(&depositor, &1000, &commitment);

    let nullifier = sample_nullifier(&env, &commitment);
    let output = sample_output_commitment(&env);
    let new_root = client.transfer(
        &mock_proof(&env),
        &root_after_deposit,
        &nullifier,
        &output,
    );

    assert_eq!(client.get_next_index(), 2);
    assert_eq!(client.is_nullifier_used(&nullifier), true);
    assert_ne!(new_root, root_after_deposit);
}

#[test]
#[should_panic(expected = "Error(Contract, #2)")]
fn test_transfer_rejects_double_spend() {
    let (env, depositor, _, _, client) = setup();
    let commitment = sample_commitment(&env);
    let root = client.deposit(&depositor, &1000, &commitment);
    let nullifier = sample_nullifier(&env, &commitment);
    let output = sample_output_commitment(&env);

    let _ = client.transfer(&mock_proof(&env), &root, &nullifier, &output);
    let new_root = client.get_root();
    let _ = client.transfer(&mock_proof(&env), &new_root, &nullifier, &output);
}

#[test]
#[should_panic(expected = "Error(Contract, #5)")]
fn test_transfer_rejects_stale_root() {
    let (env, depositor, _, _, client) = setup();
    let commitment = sample_commitment(&env);
    let _ = client.deposit(&depositor, &1000, &commitment);
    let nullifier = sample_nullifier(&env, &commitment);
    let output = sample_output_commitment(&env);

    let _ = client.transfer(
        &mock_proof(&env),
        &zero_hash(&env),
        &nullifier,
        &output,
    );
}

#[test]
#[should_panic(expected = "Error(Contract, #3)")]
fn test_transfer_rejects_short_proof() {
    let (env, depositor, _, _, client) = setup();
    let commitment = sample_commitment(&env);
    let root = client.deposit(&depositor, &1000, &commitment);
    let nullifier = sample_nullifier(&env, &commitment);
    let output = sample_output_commitment(&env);
    let short_proof = Bytes::from_array(&env, &[1u8; 8]);

    let _ = client.transfer(&short_proof, &root, &nullifier, &output);
}

#[test]
fn test_withdraw_transfers_public_funds() {
    let (env, depositor, recipient, _, client) = setup();
    let commitment = sample_commitment(&env);
    let root = client.deposit(&depositor, &1000, &commitment);
    let nullifier = sample_nullifier(&env, &commitment);

    client.withdraw(
        &mock_proof(&env),
        &root,
        &nullifier,
        &500,
        &recipient,
        &U256::from_u32(&env, 2748),
    );

    let token = client.get_token();
    let token_client = TokenClient::new(&env, &token);
    assert_eq!(token_client.balance(&recipient), 500);
    assert_eq!(client.is_nullifier_used(&nullifier), true);
}

#[test]
#[should_panic(expected = "Error(Contract, #4)")]
fn test_withdraw_rejects_zero_amount() {
    let (env, depositor, recipient, _, client) = setup();
    let commitment = sample_commitment(&env);
    let root = client.deposit(&depositor, &1000, &commitment);
    let nullifier = sample_nullifier(&env, &commitment);

    let _ = client.withdraw(
        &mock_proof(&env),
        &root,
        &nullifier,
        &0,
        &recipient,
        &U256::from_u32(&env, 2748),
    );
}

#[test]
fn test_merkle_insert_matches_noir_fixture_path() {
    let env = Env::default();
    let commitment = sample_commitment(&env);
    let path = zero_array(&env);
    let indices = [false; 8];
    let expected = compute_merkle_root(&env, &commitment, &path, &indices);

    let mut tree = MerkleTree::empty(&env);
    tree.insert(&env, commitment.clone());
    assert_eq!(tree.root(), expected);
}

#[test]
fn test_poseidon_hashes_are_non_zero() {
    let env = Env::default();
    let secret = U256::from_u32(&env, 42);
    let h = hash_1(&env, &secret);
    assert_ne!(h, zero_hash(&env));
}
