//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// @title InterepGroups interface.
/// @dev Interface of a InterepGroups contract.
interface IInterepGroups {
    struct OffchainGroup {
        uint256 root;
        uint8 depth;
    }

    /// @dev Emitted when an offchain group is updated.
    /// @param groupId: Id of the group.
    /// @param root: Root hash of the tree.
    /// @param depth: Depth of the tree.
    event OffchainGroupAdded(uint256 indexed groupId, uint256 root, uint8 depth);

    /// @dev Adds a list of offchain groups. It is useful to ensure the integrity of the Interep offchain trees.
    /// @param groupIds: List of the group ids.
    /// @param groups: List of the offchain groups (with tree depth and root).
    function addOffchainGroups(uint256[] calldata groupIds, OffchainGroup[] calldata groups) external;

    /// @dev Creates a new onchain group. Only the admin will be able to add or remove members.
    /// @param groupId: Id of the group.
    /// @param depth: Depth of the tree.
    /// @param admin: Admin of the group.
    function createGroup(
        uint256 groupId,
        uint8 depth,
        address admin
    ) external;

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
