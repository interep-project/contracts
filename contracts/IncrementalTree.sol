// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Hash} from "./Hash.sol";

struct TreeData {
    uint8 depth;
    uint256 root;
    uint256 numberOfLeaves;
    mapping(uint256 => uint256) zeroes;
    mapping(uint256 => uint256[2]) lastNodes;
}

library IncrementalTree {
    uint8 internal constant MAX_DEPTH = 32;
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

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

    function insert(TreeData storage self, uint256 leaf) public {
        require(leaf < SNARK_SCALAR_FIELD, "IncrementalTree: leaf must be < SNARK_SCALAR_FIELD");
        require(self.numberOfLeaves < 2**self.depth, "IncrementalTree: tree is full");

        uint256 index = self.numberOfLeaves;
        uint256 hash = leaf;

        for (uint8 i = 0; i < self.depth; i++) {
            if (index % 2 == 0) {
                self.lastNodes[i] = [hash, self.zeroes[i]];
            } else {
                self.lastNodes[i][1] = hash;
            }

            hash = Hash.poseidon(self.lastNodes[i]);
            index /= 2;
        }

        self.root = hash;
        self.numberOfLeaves += 1;
    }

    function remove(
        TreeData storage self,
        uint256 leaf,
        uint8[] memory path,
        uint256[] memory siblingNodes
    ) public {
        require(verify(self, leaf, path, siblingNodes), "IncrementalTree: leaf is not part of the tree");

        uint256 hash = self.zeroes[0];

        for (uint8 i = 0; i < self.depth; i++) {
            if (path[i] % 2 == 0) {
                if (siblingNodes[i] == self.lastNodes[i][1]) {
                    self.lastNodes[i][0] = hash;
                }

                hash = Hash.poseidon([hash, siblingNodes[i]]);
            } else {
                if (siblingNodes[i] == self.lastNodes[i][0]) {
                    self.lastNodes[i][1] = hash;
                }

                hash = Hash.poseidon([siblingNodes[i], hash]);
            }
        }

        self.root = hash;
    }

    function verify(
        TreeData storage self,
        uint256 leaf,
        uint8[] memory path,
        uint256[] memory siblingNodes
    ) private view returns (bool) {
        require(leaf < SNARK_SCALAR_FIELD, "IncrementalTree: leaf must be < SNARK_SCALAR_FIELD");
        require(
            path.length == self.depth && siblingNodes.length == self.depth,
            "IncrementalTree: length of path is not correct"
        );

        uint256 hash = leaf;

        for (uint8 i = 0; i < self.depth; i++) {
            require(siblingNodes[i] < SNARK_SCALAR_FIELD, "IncrementalTree: sibling node must be < SNARK_SCALAR_FIELD");

            if (path[i] % 2 == 0) {
                hash = Hash.poseidon([hash, siblingNodes[i]]);
            } else {
                hash = Hash.poseidon([siblingNodes[i], hash]);
            }
        }

        return hash == self.root;
    }
}
