// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IInterepGroups.sol";
import "@appliedzkp/semaphore-contracts/base/SemaphoreGroups.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Interep groups
/// @dev Each Interep group is actually a Merkle tree, whose leaves represent the members of the group.
/// `Depth` and `root` therefore refer to the tree. Interep groups can be divided into two types:
/// onchain groups managed entirely with the `SemaphoreGroups` contracts, and offchain groups managed
/// by Interep's servers. The tree roots used in offchain groups are updated at regular intervals
/// by Interep with the `addOffchainGroups` function.
contract InterepGroups is IInterepGroups, Ownable, SemaphoreGroups {
    /// @dev Gets a group id and returns the offchain group (tree root and depth).
    mapping(uint256 => OffchainGroup) public offchainGroups;

    /// @dev Gets a group id and returns the group admin address.
    mapping(uint256 => address) public groupAdmins;

    /// @dev See {IInterepGroups-addOffchainGroups}.
    function addOffchainGroups(uint256[] calldata groupIds, OffchainGroup[] calldata groups)
        external
        override
        onlyOwner
    {
        require(groupIds.length == groups.length, "InterepGroups: parameters lists does not have the same length");

        for (uint8 i = 0; i < groupIds.length; i++) {
            require(getDepth(groupIds[i]) == 0, "InterepGroups: group id already exists onchain");

            offchainGroups[groupIds[i]] = groups[i];

            emit OffchainGroupAdded(groupIds[i], groups[i].root, groups[i].depth);
        }
    }

    /// @dev See {IInterepGroups-createGroup}.
    function createGroup(
        uint256 groupId,
        uint8 depth,
        address admin
    ) external override {
        _createGroup(groupId, depth);

        groupAdmins[groupId] = admin;
    }

    /// @dev See {IInterepGroups-addMember}.
    function addMember(uint256 groupId, uint256 identityCommitment) external override {
        require(groupAdmins[groupId] == _msgSender(), "InterepGroups: caller is not the group admin");

        _addMember(groupId, identityCommitment);
    }

    /// @dev See {IInterepGroups-removeMember}.
    function removeMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external override {
        require(groupAdmins[groupId] == _msgSender(), "InterepGroups: caller is not the group admin");

        _removeMember(groupId, identityCommitment, proofSiblings, proofPathIndices);
    }

    /// @dev See {IInterepGroups-getOffchainRoot}.
    function getOffchainRoot(uint256 groupId) public view override returns (uint256) {
        return offchainGroups[groupId].root;
    }

    /// @dev See {IInterepGroups-getOffchainDepth}.
    function getOffchainDepth(uint256 groupId) public view override returns (uint8) {
        return offchainGroups[groupId].depth;
    }
}
