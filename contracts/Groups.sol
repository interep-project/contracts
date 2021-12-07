// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IncrementalTree, TreeData} from "./IncrementalTree.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title InterRep groups.
/// @dev InterRep allows DApps and external services to verify when their users are real or when
/// they have certain properties. Users are added to our groups, which are managed as
/// binary Merkle trees. InterRep will allow you to verify whether or not a user is part of the group
/// without revealing their identity. The integrity of the groups is guaranteed by this contract,
/// while anonymity is ensured through zero-knowledge technologies.
contract Groups is OwnableUpgradeable {
    using IncrementalTree for TreeData;

    /// @dev Emitted when an offchain group is updated. It is useful to ensure the integrity of offchain group trees.
    /// @param provider: Provider of the group.
    /// @param name: Name of the group.
    /// @param root: New root hash of the tree.
    event OffchainMerkleRoot(bytes32 indexed provider, bytes32 indexed name, uint256 root);

    /// @dev Emitted when a new group is created.
    /// @param provider: Provider of the group.
    /// @param name: Name of the group.
    /// @param depth: Depth of the tree.
    event GroupAdded(bytes32 indexed provider, bytes32 name, uint8 depth);

    /// @dev Emitted when a new identity commitment is added.
    /// @param provider: Provider of the group.
    /// @param name: Name of the group.
    /// @param identityCommitment: New identity commitment.
    /// @param root: New root hash of the tree.
    event IdentityCommitmentAdded(
        bytes32 indexed provider,
        bytes32 indexed name,
        uint256 identityCommitment,
        uint256 root
    );

    /// @dev Emitted when a new identity commitment is deleted.
    /// @param provider: Provider of the group.
    /// @param name: Name of the group.
    /// @param identityCommitment: New identity commitment.
    /// @param root: New root hash of the tree.
    event IdentityCommitmentDeleted(
        bytes32 indexed provider,
        bytes32 indexed name,
        uint256 identityCommitment,
        uint256 root
    );

    /// @dev Gets a group id and returns the group/tree data.
    mapping(bytes32 => TreeData) private groups;

    /// @dev Gets a group id and returns the group admin address.
    mapping(bytes32 => address) private groupAdmins;

    /// @dev OpenZeppelin initialize function.
    function initialize() public initializer {
        // Call ownable super initialize function.
        __Ownable_init();
    }

    /// @dev Emits events with the new Merkle root of offchain groups.
    /// @param providers: Providers of the groups.
    /// @param names: Names of the groups.
    /// @param roots: New root hashes of the trees.
    function publishOffchainMerkleRoots(
        bytes32[] memory providers,
        bytes32[] memory names,
        uint256[] memory roots
    ) external onlyOwner {
        require(
            providers.length == names.length && names.length == roots.length,
            "Groups: parameters lists does not have the same length"
        );

        for (uint8 i = 0; i < providers.length; i++) {
            OffchainMerkleRoot(providers[i], names[i], roots[i]);
        }
    }

    /// @dev Creates a new group by initializing the associated Merkle tree.
    /// @param provider: Provider of the group.
    /// @param name: Name of the group.
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

        emit GroupAdded(provider, name, depth);
    }

    /// @dev Adds an identity commitment to an existing group.
    /// @param provider: Provider of the group.
    /// @param name: Name of the group.
    /// @param identityCommitment: New identity commitment.
    function addIdentityCommitment(
        bytes32 provider,
        bytes32 name,
        uint256 identityCommitment
    ) external {
        bytes32 groupId = getGroupId(provider, name);

        require(groups[groupId].depth != 0, "Groups: group does not exist");
        require(groupAdmins[groupId] == _msgSender(), "Groups: caller is not the group admin");

        groups[groupId].insert(identityCommitment);

        emit IdentityCommitmentAdded(provider, name, identityCommitment, groups[groupId].root);
    }

    /// @dev Deletes an identity commitment from an existing group. A proof of membership is
    /// needed to check if the node to be deleted is part of the onchain tree.
    /// @param provider: Provider of the group.
    /// @param name: Name of the group.
    /// @param identityCommitment: Identity commitment to be deleted.
    /// @param proofSiblingNodes: Array of the sibling nodes of the proof of membership.
    /// @param proofPath: Path of the proof of membership.
    function deleteIdentityCommitment(
        bytes32 provider,
        bytes32 name,
        uint256 identityCommitment,
        uint256[] memory proofSiblingNodes,
        uint8[] memory proofPath
    ) external {
        bytes32 groupId = getGroupId(provider, name);

        require(groups[groupId].depth != 0, "Groups: group does not exist");
        require(groupAdmins[groupId] == _msgSender(), "Groups: caller is not the group admin");

        groups[groupId].remove(identityCommitment, proofSiblingNodes, proofPath);

        emit IdentityCommitmentDeleted(provider, name, identityCommitment, groups[groupId].root);
    }

    /// @dev Returns the last root hash of the group.
    /// @param provider: Provider of the group.
    /// @param name: Name of the group.
    /// @return Root hash of the group.
    function getRoot(bytes32 provider, bytes32 name) external view returns (uint256) {
        bytes32 groupId = getGroupId(provider, name);

        return groups[groupId].root;
    }

    /// @dev Returns the size of the group.
    /// @param provider: Provider of the group.
    /// @param name: Name of the group.
    /// @return Size of the group.
    function getSize(bytes32 provider, bytes32 name) external view returns (uint256) {
        bytes32 groupId = getGroupId(provider, name);

        return groups[groupId].numberOfLeaves;
    }

    /// @dev Returns the group id.
    /// @param provider: Provider of the group.
    /// @param name: Name of the group.
    /// @return Group id.
    function getGroupId(bytes32 provider, bytes32 name) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(provider, name));
    }
}
