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
    /// @param index: The index of the identity commitment in the tree.
    /// @param root: The new root hash of the tree.
    event NewIdentityCommitment(
        bytes32 indexed provider,
        bytes32 indexed name,
        uint256 identityCommitment,
        uint256 index,
        uint256 root
    );

    /// @dev Gets a group id and returns the group/tree data.
    mapping(bytes32 => TreeData) private groups;

    /// @dev Gets a group id and returns the group admin address.
    mapping(bytes32 => address) private groupAdmins;

    function initialize() public initializer {
        __Ownable_init();
    }

    /// @dev ...
    /// @param provider: The provider of the group.
    /// @param name: The name of the group.
    /// @param depth: Depth of the tree.
    function createOwnableGroup(
        bytes32 provider,
        bytes32 name,
        uint8 depth,
        address admin
    ) external {
        createGroup(provider, name, depth);

        require(admin != owner(), "Groups: group admin cannot be the contract owner");

        bytes32 groupId = getGroupId(provider, name);

        groupAdmins[groupId] = admin;
    }

    /// @dev ...
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

    /// @dev Gets a group provider and a group name and returns the last root hash of the group.
    /// @return The root hash.
    function getRoot(bytes32 provider, bytes32 name) external view returns (uint256) {
        bytes32 groupId = getGroupId(provider, name);

        return groups[groupId].root;
    }

    /// @dev Gets a group provider and a group name and returns the size of the group.
    /// @return The root hash.
    function getSize(bytes32 provider, bytes32 name) external view returns (uint256) {
        bytes32 groupId = getGroupId(provider, name);

        return groups[groupId].numberOfLeaves;
    }

    /// @dev ...
    /// @param provider: The provider of the group.
    /// @param name: The name of the group.
    /// @param depth: Depth of the tree.
    function createGroup(
        bytes32 provider,
        bytes32 name,
        uint8 depth
    ) public onlyOwner {
        bytes32 groupId = getGroupId(provider, name);

        require(groups[groupId].depth == 0, "Groups: group already exists");

        groups[groupId].init(depth, 0);

        emit NewGroup(provider, name, depth);
    }

    /// @dev ...
    /// @param provider: The provider of the group.
    /// @param name: The name of the group.
    /// @param identityCommitment: The new identity commitment.
    function addIdentityCommitment(
        bytes32 provider,
        bytes32 name,
        uint256 identityCommitment
    ) public {
        bytes32 groupId = getGroupId(provider, name);

        require(
            (owner() == _msgSender() && groupAdmins[groupId] == address(0)) || groupAdmins[groupId] == _msgSender(),
            "Groups: caller is not the contract owner or the group admin"
        );
        require(groups[groupId].depth != 0, "Groups: group does not exist");

        groups[groupId].insert(identityCommitment);

        emit NewIdentityCommitment(
            provider,
            name,
            identityCommitment,
            groups[groupId].numberOfLeaves - 1,
            groups[groupId].root
        );
    }

    function getGroupId(bytes32 provider, bytes32 name) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(provider, name));
    }
}
