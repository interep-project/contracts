// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IncrementalTree, TreeData} from "./IncrementalTree.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Groups is OwnableUpgradeable {
    using IncrementalTree for TreeData;

    /// @dev Emitted when a new group is created.
    /// @param provider: The provider of the group.
    /// @param name: The name of the group.
    /// @param depth: The depth of the tree.
    event NewGroup(bytes32 indexed provider, bytes32 name, uint8 depth);

    /// @dev Emitted when a new identity commitment is added.
    /// @param provider: The provider of the group.
    /// @param name: The name of the group.
    /// @param identityCommitment: The new identity commitment.
    /// @param root: The new root hash of the tree.
    event NewIdentityCommitment(
        bytes32 indexed provider,
        bytes32 indexed name,
        uint256 identityCommitment,
        uint256 root
    );

    /// @dev Emitted when a new identity commitment is deleted.
    /// @param provider: The provider of the group.
    /// @param name: The name of the group.
    /// @param identityCommitment: The new identity commitment.
    /// @param root: The new root hash of the tree.
    event DeleteIdentityCommitment(
        bytes32 indexed provider,
        bytes32 indexed name,
        uint256 identityCommitment,
        uint256 root
    );

    /// @dev Gets a group id and returns the group/tree data.
    mapping(bytes32 => TreeData) private groups;

    /// @dev Gets a group id and returns the group admin address.
    mapping(bytes32 => address) private groupAdmins;

    function initialize() public initializer {
        __Ownable_init();
    }

    /// @dev Creates a new group by initializing the associated Merkle tree.
    /// @param provider: The provider of the group.
    /// @param name: The name of the group.
    /// @param depth: Depth of the tree.
    /// @param admin: Admin of the group.
    function createGroup(
        bytes32 provider,
        bytes32 name,
        uint8 depth,
        address admin
    ) external onlyOwner {
        bytes32 groupId = getGroupId(provider, name);

        require(groups[groupId].depth == 0, "Groups: group already exists");

        groups[groupId].init(depth, 0);

        groupAdmins[groupId] = admin;

        emit NewGroup(provider, name, depth);
    }

    /// @dev Batch function to add multiple identity commitments.
    /// @param provider: The provider of the group.
    /// @param names: The names of the group.
    /// @param identityCommitments: Identity commitments.
    function batchAddIdentityCommitment(
        bytes32 provider,
        bytes32[] memory names,
        uint256[] memory identityCommitments
    ) external {
        require(names.length == identityCommitments.length, "Groups: array parameters should have the same length");

        for (uint256 i = 0; i < names.length; i++) {
            addIdentityCommitment(provider, names[i], identityCommitments[i]);
        }
    }

    /// @dev Returns the last root hash of the group.
    /// @return The root hash.
    function getRoot(bytes32 provider, bytes32 name) external view returns (uint256) {
        bytes32 groupId = getGroupId(provider, name);

        return groups[groupId].root;
    }

    /// @dev Returns the size of the group.
    /// @return The root hash.
    function getSize(bytes32 provider, bytes32 name) external view returns (uint256) {
        bytes32 groupId = getGroupId(provider, name);

        return groups[groupId].numberOfLeaves;
    }

    /// @dev Adds an identity commitment to an existing group.
    /// @param provider: The provider of the group.
    /// @param name: The name of the group.
    /// @param identityCommitment: The new identity commitment.
    function addIdentityCommitment(
        bytes32 provider,
        bytes32 name,
        uint256 identityCommitment
    ) public {
        bytes32 groupId = getGroupId(provider, name);

        require(groups[groupId].depth != 0, "Groups: group does not exist");
        require(groupAdmins[groupId] == _msgSender(), "Groups: caller is not the group admin");

        groups[groupId].insert(identityCommitment);

        emit NewIdentityCommitment(provider, name, identityCommitment, groups[groupId].root);
    }

    /// @dev Deletes an identity commitment from an existing group.
    /// @param provider: The provider of the group.
    /// @param name: The name of the group.
    /// @param identityCommitment: The new identity commitment.
    /// @param path: The new identity commitment.
    /// @param siblingNodes: The new identity commitment.
    function deleteIdentityCommitment(
        bytes32 provider,
        bytes32 name,
        uint256 identityCommitment,
        uint8[] memory path,
        uint256[] memory siblingNodes
    ) public {
        bytes32 groupId = getGroupId(provider, name);

        require(groups[groupId].depth != 0, "Groups: group does not exist");
        require(groupAdmins[groupId] == _msgSender(), "Groups: caller is not the group admin");

        groups[groupId].remove(identityCommitment, path, siblingNodes);

        emit DeleteIdentityCommitment(provider, name, identityCommitment, groups[groupId].root);
    }

    /// @dev Returns the group id.
    /// @param provider: The provider of the group.
    /// @param name: The name of the group.
    function getGroupId(bytes32 provider, bytes32 name) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(provider, name));
    }
}
