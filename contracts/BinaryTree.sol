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

library BinaryTree {
    uint8 internal constant MAX_DEPTH = 32;
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    function init(
        TreeData storage self,
        uint8 _depth,
        uint256 _zero
    ) public {
        require(_depth > 0 && _depth <= MAX_DEPTH, "The tree depth must be between 1 and 32");

        self.depth = _depth;

        for (uint8 i = 0; i < _depth; i++) {
            self.zeroes[i] = _zero;
            _zero = Hash.poseidon([_zero, _zero]);
        }
    }

    function insert(TreeData storage self, uint256 _leaf) public returns (uint256) {
        require(_leaf < SNARK_SCALAR_FIELD, "The leaf must be < SNARK_SCALAR_FIELD");
        require(self.numberOfLeaves < 2**self.depth, "The tree is full");

        uint256 index = self.numberOfLeaves;
        uint256 hash = _leaf;

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

        return self.root;
    }
}
