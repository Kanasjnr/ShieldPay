#![no_std]

mod crypto_util;
mod merkle;
mod verifier;

use crypto_util::MERKLE_DEPTH;
use merkle::MerkleTree;
use soroban_sdk::{
    contract, contracterror, contractimpl, contracttype, symbol_short, Address, Bytes, Env,
    Map, Symbol, U256,
};
use soroban_sdk::token::TokenClient;

const TOKEN_KEY: Symbol = symbol_short!("TOKEN");
const ADMIN_KEY: Symbol = symbol_short!("ADMIN");
const ROOT_KEY: Symbol = symbol_short!("ROOT");
const NEXT_KEY: Symbol = symbol_short!("NEXT");
const NULLIFIERS_KEY: Symbol = symbol_short!("NULLS");

#[contracterror]
#[derive(Copy, Clone, Debug, Eq, PartialEq, PartialOrd, Ord)]
#[repr(u32)]
pub enum Error {
    Unauthorized = 1,
    NullifierSpent = 2,
    InvalidProof = 3,
    InvalidAmount = 4,
    RootMismatch = 5,
}

#[contracttype]
#[derive(Clone)]
pub enum DataKey {
    FilledSubtree(u32),
}

#[contract]
pub struct ShieldPool;

#[contractimpl]
impl ShieldPool {
    pub fn initialize(env: Env, admin: Address, token: Address) {
        if env.storage().instance().has(&ADMIN_KEY) {
            panic!("already initialized");
        }
        env.storage().instance().set(&ADMIN_KEY, &admin);
        env.storage().instance().set(&TOKEN_KEY, &token);

        let tree = MerkleTree::empty(&env);
        Self::write_tree(&env, &tree);
        env.storage().instance().set(&NULLIFIERS_KEY, &Map::<U256, bool>::new(&env));
    }

    /// Escrow public USDC and append a shielded commitment to the Merkle tree.
    pub fn deposit(env: Env, from: Address, amount: i128, commitment: U256) -> Result<U256, Error> {
        from.require_auth();
        if amount <= 0 {
            return Err(Error::InvalidAmount);
        }

        let token = Self::token(&env);
        let contract = env.current_contract_address();
        TokenClient::new(&env, &token).transfer(&from, &contract, &amount);

        let mut tree = Self::read_tree(&env);
        tree.insert(&env, commitment);
        Self::write_tree(&env, &tree);

        Ok(tree.root())
    }

    /// Validate a shielded transfer proof, consume the nullifier, and append the
    /// output commitment to the Merkle tree.
    pub fn transfer(
        env: Env,
        proof: Bytes,
        merkle_root: U256,
        nullifier: U256,
        output_commitment: U256,
    ) -> Result<U256, Error> {
        let tree = Self::read_tree(&env);
        if merkle_root != tree.root() {
            return Err(Error::RootMismatch);
        }
        if Self::is_nullifier_spent(&env, &nullifier) {
            return Err(Error::NullifierSpent);
        }
        if !verifier::verify_transfer_proof(
            &env,
            &proof,
            &merkle_root,
            &nullifier,
            &output_commitment,
            &tree.root(),
        ) {
            return Err(Error::InvalidProof);
        }

        Self::mark_nullifier_spent(&env, nullifier);

        let mut tree = tree;
        tree.insert(&env, output_commitment);
        Self::write_tree(&env, &tree);
        Ok(tree.root())
    }

    /// Unshield funds to a public recipient after validating the withdraw proof.
    pub fn withdraw(
        env: Env,
        proof: Bytes,
        merkle_root: U256,
        nullifier: U256,
        amount: i128,
        recipient: Address,
        recipient_hash: U256,
    ) -> Result<(), Error> {
        if amount <= 0 {
            return Err(Error::InvalidAmount);
        }

        let tree = Self::read_tree(&env);
        if merkle_root != tree.root() {
            return Err(Error::RootMismatch);
        }
        if Self::is_nullifier_spent(&env, &nullifier) {
            return Err(Error::NullifierSpent);
        }
        if !verifier::verify_withdraw_proof(
            &env,
            &proof,
            &merkle_root,
            &nullifier,
            amount,
            &recipient_hash,
            &tree.root(),
        ) {
            return Err(Error::InvalidProof);
        }

        Self::mark_nullifier_spent(&env, nullifier);

        let token = Self::token(&env);
        let contract = env.current_contract_address();
        TokenClient::new(&env, &token).transfer(&contract, &recipient, &amount);
        Ok(())
    }

    pub fn get_root(env: Env) -> U256 {
        Self::read_tree(&env).root()
    }

    pub fn get_next_index(env: Env) -> u32 {
        Self::read_tree(&env).next_index()
    }

    pub fn is_nullifier_used(env: Env, nullifier: U256) -> bool {
        Self::is_nullifier_spent(&env, &nullifier)
    }

    pub fn get_token(env: Env) -> Address {
        env.storage().instance().get(&TOKEN_KEY).unwrap()
    }

    fn token(env: &Env) -> Address {
        env.storage().instance().get(&TOKEN_KEY).unwrap()
    }

    fn read_tree(env: &Env) -> MerkleTree {
        let root: U256 = env.storage().instance().get(&ROOT_KEY).unwrap();
        let next_index: u32 = env.storage().instance().get(&NEXT_KEY).unwrap();
        let mut filled_subtrees = crypto_util::zero_array(env);
        for i in 0..MERKLE_DEPTH {
            let key = DataKey::FilledSubtree(i);
            filled_subtrees[i as usize] = env.storage().instance().get(&key).unwrap();
        }
        MerkleTree::from_parts(root, next_index, filled_subtrees)
    }

    fn write_tree(env: &Env, tree: &MerkleTree) {
        env.storage().instance().set(&ROOT_KEY, &tree.root());
        env.storage().instance().set(&NEXT_KEY, &tree.next_index());
        for i in 0..MERKLE_DEPTH {
            let key = DataKey::FilledSubtree(i);
            env.storage()
                .instance()
                .set(&key, &tree.filled_subtrees()[i as usize]);
        }
    }

    fn is_nullifier_spent(env: &Env, nullifier: &U256) -> bool {
        let map: Map<U256, bool> = env.storage().instance().get(&NULLIFIERS_KEY).unwrap();
        map.get(nullifier.clone()).unwrap_or(false)
    }

    fn mark_nullifier_spent(env: &Env, nullifier: U256) {
        let mut map: Map<U256, bool> = env.storage().instance().get(&NULLIFIERS_KEY).unwrap();
        map.set(nullifier, true);
        env.storage().instance().set(&NULLIFIERS_KEY, &map);
    }
}

mod test;
