//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// @title Interep interface.
/// @dev Interface of a Interep contract.
interface IInterep {
    struct OffchainGroup {
        uint256 root;
        uint8 depth;
    }

    /// @dev Emitted when a Semaphore proof is verified.
    /// @param groupId: Id of the group.
    /// @param signal: Semaphore signal.
    event ProofVerified(uint256 indexed groupId, string signal);

    /// @dev Emitted when an offchain group is updated.
    /// @param groupId: Id of the group.
    /// @param root: Root hash of the tree.
    /// @param depth: Depth of the tree.
    event OffchainGroupUpdated(uint256 indexed groupId, uint256 root, uint8 indexed depth);

    /// @dev Emitted when an admin is assigned to an onchain group.
    /// @param groupId: Id of the group.
    /// @param oldAdmin: Old admin of the group.
    /// @param newAdmin: New admin of the group.
    event GroupAdminUpdated(uint256 indexed groupId, address indexed oldAdmin, address indexed newAdmin);

    /// @dev Updates a list of offchain groups. It is useful to ensure the integrity of the Interep offchain trees.
    /// @param groupIds: List of the group ids.
    /// @param groups: List of the offchain groups (with tree depth and root).
    function updateOffchainGroups(uint256[] calldata groupIds, OffchainGroup[] calldata groups) external;

    /// @dev Saves the nullifier hash to avoid double signaling and exit an event
    /// if the zero-knowledge proof is valid.
    /// @param groupId: Id of the group.
    /// @param signal: Semaphore signal.
    /// @param nullifierHash: Nullifier hash.
    /// @param externalNullifier: External nullifier.
    /// @param proof: Zero-knowledge proof.
    function verifyProof(
        uint256 groupId,
        string calldata signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external;

    /// @dev Creates a new onchain group. Only the admin will be able to add or remove members.
    /// @param groupId: Id of the group.
    /// @param depth: Depth of the tree.
    /// @param admin: Admin of the group.
    function createGroup(
        uint256 groupId,
        uint8 depth,
        address admin
    ) external;

    /// @dev Updates the admin of an onchain group.
    /// @param groupId: Id of the group.
    /// @param newAdmin: New admin of the group.
    function updateGroupAdmin(uint256 groupId, address newAdmin) external;

    /// @dev Adds a new member to an existing onchain group.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: New identity commitment.
    function addMember(uint256 groupId, uint256 identityCommitment) external;

    /// @dev Removes a member from an existing onchain group. A proof of membership is
    /// needed to check if the node to be removed is part of the onchain tree.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: Identity commitment to be deleted.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function removeMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external;

    /// @dev Returns the root hash of an offchain group.
    /// @param groupId: Id of the group.
    /// @return Root hash of the group.
    function getOffchainRoot(uint256 groupId) external view returns (uint256);

    /// @dev Returns the tree depth of an offchain group.
    /// @param groupId: Id of the group.
    /// @return Tree depth of the group.
    function getOffchainDepth(uint256 groupId) external view returns (uint8);
}
