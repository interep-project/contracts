// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Hash} from "./Hash.sol";

// Each incremental tree has certain properties and data that will
// be used to add new leaves.
struct TreeData {
    uint8 depth; // Depth of the tree (levels - 1).
    uint256 root; // Root hash of the tree.
    uint256 numberOfLeaves; // Number of leaves of the tree.
    mapping(uint256 => uint256) zeroes; // Zero hashes used for empty nodes (level -> zero hash).
    // The nodes of the subtrees used in the last addition of a leaf (level -> [left node, right node]).
    mapping(uint256 => uint256[2]) lastSubtrees; // Caching these values is essential to efficient appends.
}

/// @title Binary incremental Merkle tree.
/// @dev The incremental tree allows to calculate the root hash each time a leaf is added, ensuring
/// the integrity of the tree.
library IncrementalTree {
    uint8 internal constant MAX_DEPTH = 32;
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /// @dev Initializes a tree.
    /// @param self: Tree data.
    /// @param depth: Depth of the tree.
    /// @param zero: Zero value to be used.
    function init(
        TreeData storage self,
        uint8 depth,
        uint256 zero
    ) public {
        require(depth > 0 && depth <= MAX_DEPTH, "IncrementalTree: tree depth must be between 1 and 32");

        self.depth = depth;

        for (uint8 i = 0; i < depth; i++) {
            self.zeroes[i] = zero;
            zero = Hash.poseidon([zero, zero]);
        }
    }

    /// @dev Inserts a leaf in the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be inserted.
    function insert(TreeData storage self, uint256 leaf) public {
        require(leaf < SNARK_SCALAR_FIELD, "IncrementalTree: leaf must be < SNARK_SCALAR_FIELD");
        require(self.numberOfLeaves < 2**self.depth, "IncrementalTree: tree is full");

        uint256 index = self.numberOfLeaves;
        uint256 hash = leaf;

        for (uint8 i = 0; i < self.depth; i++) {
            if (index % 2 == 0) {
                self.lastSubtrees[i] = [hash, self.zeroes[i]];
            } else {
                self.lastSubtrees[i][1] = hash;
            }

            hash = Hash.poseidon(self.lastSubtrees[i]);
            index /= 2;
        }

        self.root = hash;
        self.numberOfLeaves += 1;
    }

    /// @dev Removes a leaf from the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be removed.
    /// @param pathSiblingNodes: Array of sibling nodes of the path, one for each tree level.
    /// @param pathPositions: Array of positions of new nodes to be added (0: left, 1: right).
    function remove(
        TreeData storage self,
        uint256 leaf,
        uint256[] memory pathSiblingNodes,
        uint8[] memory pathPositions
    ) public {
        require(verify(self, leaf, pathSiblingNodes, pathPositions), "IncrementalTree: leaf is not part of the tree");

        uint256 hash = self.zeroes[0];

        for (uint8 i = 0; i < self.depth; i++) {
            if (pathPositions[i] == 0) {
                if (pathSiblingNodes[i] == self.lastSubtrees[i][1]) {
                    self.lastSubtrees[i][0] = hash;
                }

                hash = Hash.poseidon([hash, pathSiblingNodes[i]]);
            } else {
                if (pathSiblingNodes[i] == self.lastSubtrees[i][0]) {
                    self.lastSubtrees[i][1] = hash;
                }

                hash = Hash.poseidon([pathSiblingNodes[i], hash]);
            }
        }

        self.root = hash;
    }

    /// @dev Verify if the path is correct and the leaf is part of the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be removed.
    /// @param pathSiblingNodes: Array of sibling nodes of the path, one for each tree level.
    /// @param pathPositions: Array of positions of new nodes to be added (0: left, 1: right).
    /// @return True or false.
    function verify(
        TreeData storage self,
        uint256 leaf,
        uint256[] memory pathSiblingNodes,
        uint8[] memory pathPositions
    ) private view returns (bool) {
        require(leaf < SNARK_SCALAR_FIELD, "IncrementalTree: leaf must be < SNARK_SCALAR_FIELD");
        require(
            pathPositions.length == self.depth && pathSiblingNodes.length == self.depth,
            "IncrementalTree: length of path is not correct"
        );

        uint256 hash = leaf;

        for (uint8 i = 0; i < self.depth; i++) {
            require(
                pathSiblingNodes[i] < SNARK_SCALAR_FIELD,
                "IncrementalTree: sibling node must be < SNARK_SCALAR_FIELD"
            );

            if (pathPositions[i] == 0) {
                hash = Hash.poseidon([hash, pathSiblingNodes[i]]);
            } else {
                hash = Hash.poseidon([pathSiblingNodes[i], hash]);
            }
        }

        return hash == self.root;
    }
}
