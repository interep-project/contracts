// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Tree, IncrementalTree} from "./IncrementalTree.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// import "hardhat/console.sol";

contract CuratedGroups is Initializable, OwnableUpgradeable {
    using IncrementalTree for Tree;

    mapping(bytes32 => Tree) public groups;

    function insertLeaf(bytes32 _groupId, uint256 _identityCommitment) public {
        if (groups[_groupId].treeLevels == 0) {
            groups[_groupId].init(16, 0);
        }

        groups[_groupId].insert(_identityCommitment);
    }
}
