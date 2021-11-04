// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BinaryTree, TreeData} from "./BinaryTree.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CuratedGroups is Initializable, OwnableUpgradeable {
    using BinaryTree for TreeData;

    /// @dev Emitted when a new root hash is added.
    /// @param _groupId: The id of the group.
    /// @param _identityCommitment: Semaphore identity commitment.
    /// @param _rootHash: The new root hash of the tree.
    event NewRootHash(bytes32 indexed _groupId, uint256 _identityCommitment, uint256 _rootHash);

    mapping(bytes32 => uint256) public rootHashes;
    mapping(bytes32 => TreeData) public groups;

    function createGroup(bytes32 _groupId, uint8 _depth) public {
        require(groups[_groupId].depth == 0, "The group already exists");

        groups[_groupId].init(_depth, 0);
    }

    function addIdentityCommitment(bytes32 _groupId, uint256 _identityCommitment) public {
        require(groups[_groupId].depth != 0, "The group does not exist");

        uint256 rootHash = groups[_groupId].insert(_identityCommitment);

        emit NewRootHash(_groupId, _identityCommitment, rootHash);
    }
}
