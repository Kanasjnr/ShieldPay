use crate::poseidon_utils::hash_2;

pub global MERKLE_DEPTH: u32 = 8;

pub fn compute_merkle_root(
    leaf: Field,
    path: [Field; 8],
    indices: [bool; 8],
) -> Field {
    let mut current = leaf;

    for i in 0..8 {
        let sibling = path[i];
        if indices[i] {
            current = hash_2(sibling, current);
        } else {
            current = hash_2(current, sibling);
        }
    }

    current
}

pub fn assert_merkle_membership(
    leaf: Field,
    path: [Field; 8],
    indices: [bool; 8],
    root: Field,
) {
    let computed = compute_merkle_root(leaf, path, indices);
    assert(computed == root, "Invalid Merkle membership proof");
}

#[test]
fn test_merkle_root_with_zero_path() {
    let leaf = 12345;
    let path: [Field; 8] = [0; 8];
    let indices: [bool; 8] = [false; 8];
    let root = compute_merkle_root(leaf, path, indices);
    assert(root != leaf);
}

#[test]
fn test_merkle_left_vs_right_sibling_order() {
    let leaf = 99;
    let sibling = 55;
    let mut path: [Field; 8] = [0; 8];
    path[0] = sibling;

    let left_indices: [bool; 8] = [false; 8];
    let mut right_indices: [bool; 8] = [true; 8];
    right_indices[0] = true;

    let root_left = compute_merkle_root(leaf, path, left_indices);
    let root_right = compute_merkle_root(leaf, path, right_indices);
    assert(root_left != root_right);
}

#[test(should_fail_with = "Invalid Merkle membership proof")]
fn test_merkle_rejects_wrong_root() {
    let leaf = 42;
    let path: [Field; 8] = [0; 8];
    let indices: [bool; 8] = [false; 8];
    assert_merkle_membership(leaf, path, indices, 999);
}
