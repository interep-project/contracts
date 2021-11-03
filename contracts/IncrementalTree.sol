// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Hash} from "./Hash.sol";

struct Tree {
    // The tree depth
    uint8 treeLevels;
    // The number of inserted leaves
    uint256 nextLeafIndex;
    // The Merkle root
    uint256 root;
    // The zero value per level
    mapping(uint256 => uint256) zeros;
    // Allows you to compute the path to the element (but it's not the path to
    // the elements). Caching these values is essential to efficient appends.
    mapping(uint256 => mapping(uint256 => uint256)) filledSubtrees;
    // Whether the contract has already seen a particular Merkle tree root
    mapping(uint256 => bool) rootHistory;
}

library IncrementalTree {
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    // The maximum tree depth.
    uint8 internal constant MAX_DEPTH = 32;

    // The number of leaves per node.
    uint8 internal constant LEAVES_PER_NODE = 2;

    function init(
        Tree storage self,
        uint8 _treeLevels,
        uint256 _zeroValue
    ) public {
        // Limit the Merkle tree to MAX_DEPTH levels
        require(_treeLevels > 0 && _treeLevels <= MAX_DEPTH, "IncrementalTree: _treeLevels must be between 0 and 33");

        self.treeLevels = _treeLevels;

        uint256 currentZero = _zeroValue;

        // Hash.poseidon requires a uint256[] memory input, so we have to use temp
        uint256[LEAVES_PER_NODE] memory temp;

        for (uint8 i = 0; i < _treeLevels; i++) {
            for (uint8 j = 0; j < LEAVES_PER_NODE; j++) {
                temp[j] = currentZero;
            }

            self.zeros[i] = currentZero;
            currentZero = Hash.poseidon(temp);
        }

        self.root = currentZero;
    }

    function insert(Tree storage self, uint256 _leaf) public returns (uint256) {
        require(_leaf < SNARK_SCALAR_FIELD, "IncrementalQuinTree: insertLeaf argument must be < SNARK_SCALAR_FIELD");

        // Ensure that the tree is not full
        require(
            self.nextLeafIndex < uint256(LEAVES_PER_NODE)**uint256(self.treeLevels),
            "IncrementalQuinTree: tree is full"
        );

        uint256 currentIndex = self.nextLeafIndex;

        uint256 currentLevelHash = _leaf;

        // Hash.poseidon requires a uint256[] memory input, so we have to use temp
        uint256[LEAVES_PER_NODE] memory temp;

        // The leaf's relative position within its node
        uint256 m = currentIndex % LEAVES_PER_NODE;

        for (uint8 i = 0; i < self.treeLevels; i++) {
            // If the leaf is at relative index 0, zero out the level in
            // filledSubtrees
            if (m == 0) {
                for (uint8 j = 1; j < LEAVES_PER_NODE; j++) {
                    self.filledSubtrees[i][j] = self.zeros[i];
                }
            }

            // Set the leaf in filledSubtrees
            self.filledSubtrees[i][m] = currentLevelHash;

            // Hash the level
            for (uint8 j = 0; j < LEAVES_PER_NODE; j++) {
                temp[j] = self.filledSubtrees[i][j];
            }
            currentLevelHash = Hash.poseidon(temp);

            currentIndex /= LEAVES_PER_NODE;
            m = currentIndex % LEAVES_PER_NODE;
        }

        self.root = currentLevelHash;
        self.rootHistory[self.root] = true;

        self.nextLeafIndex += 1;

        return currentIndex;
    }
}
