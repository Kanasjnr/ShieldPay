use crate::crypto_util::{hash_2, zero_array, zero_hash, MERKLE_DEPTH};
use soroban_sdk::{Env, U256};

pub struct MerkleTree {
    root: U256,
    next_index: u32,
    filled_subtrees: [U256; MERKLE_DEPTH as usize],
}

impl MerkleTree {
    pub fn empty(env: &Env) -> Self {
        let zero = zero_hash(env);
        Self {
            root: zero.clone(),
            next_index: 0,
            filled_subtrees: zero_array(env),
        }
    }

    pub fn root(&self) -> U256 {
        self.root.clone()
    }

    pub fn next_index(&self) -> u32 {
        self.next_index
    }

    pub fn filled_subtrees(&self) -> [U256; MERKLE_DEPTH as usize] {
        self.filled_subtrees.clone()
    }

    pub fn from_parts(
        root: U256,
        next_index: u32,
        filled_subtrees: [U256; MERKLE_DEPTH as usize],
    ) -> Self {
        Self {
            root,
            next_index,
            filled_subtrees,
        }
    }

    pub fn insert(&mut self, env: &Env, leaf: U256) {
        let mut index = self.next_index;
        self.next_index += 1;

        let mut current = leaf;
        let zero = zero_hash(env);
        for level in 0..MERKLE_DEPTH {
            if index % 2 == 0 {
                self.filled_subtrees[level as usize] = current.clone();
                current = hash_2(env, &current, &zero);
            } else {
                let left = self.filled_subtrees[level as usize].clone();
                current = hash_2(env, &left, &current);
            }
            index /= 2;
        }
        self.root = current;
    }
}
