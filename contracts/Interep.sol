// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IInterep.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@appliedzkp/semaphore-contracts/interfaces/IVerifier.sol";
import "@appliedzkp/semaphore-contracts/base/SemaphoreCore.sol";
import "@appliedzkp/semaphore-contracts/base/SemaphoreGroups.sol";

/// @title Interep
/// @dev Interep is a collection of groups (onchain and offchain) where members can prove
/// their membership without revealing their identity. DApps can use this contract to verify
/// if a Semaphore proof is valid and then use its signal.
/// Each Interep group is actually a Merkle tree, whose leaves represent the members of the group.
/// `depth` and `root` therefore refer to the tree. Interep groups can be divided into two types:
/// onchain groups managed entirely with the `SemaphoreGroups` contracts, and offchain groups managed
/// by Interep's servers. The tree roots used in offchain groups are updated at regular intervals
/// by Interep with the `addOffchainGroups` function.
contract Interep is IInterep, Ownable, SemaphoreCore, SemaphoreGroups {
    /// @dev Gets a tree depth and returns its verifier address.
    mapping(uint8 => IVerifier) public verifiers;

    /// @dev Gets a group id and returns the offchain group (tree root and depth).
    mapping(uint256 => OffchainGroup) public offchainGroups;

    /// @dev Gets a group id and returns the group admin address.
    mapping(uint256 => address) public groupAdmins;

    /// @dev Checks if the group admin is the transaction sender.
    /// @param groupId: Id of the group.
    modifier onlyGroupAdmin(uint256 groupId) {
        require(groupAdmins[groupId] == _msgSender(), "Interep: caller is not the group admin");
        _;
    }

    /// @dev Checks if there is a verifier for the given tree depth.
    /// @param depth: Depth of the tree.
    modifier onlySupportedDepth(uint8 depth) {
        require(address(verifiers[depth]) != address(0), "Interep: tree depth is not supported");
        _;
    }

    /// @dev Since there can be multiple verifier contracts (each associated with a certain tree depth),
    /// it is necessary to pass the addresses of the previously deployed verifier contracts with the associated
    /// tree depth. Depending on the depth chosen when creating the poll, a certain verifier will be
    /// used to verify that the proof is correct.
    /// @param depths: Three depths used in verifiers.
    /// @param verifierAddresses: Verifier addresses.
    constructor(uint8[] memory depths, address[] memory verifierAddresses) {
        require(depths.length == verifierAddresses.length, "Interep: parameters lists does not have the same length");

        for (uint8 i = 0; i < depths.length; i++) {
            verifiers[depths[i]] = IVerifier(verifierAddresses[i]);
        }
    }

    /// @dev See {IInterep-verifyProof}.
    function verifyProof(
        uint256 groupId,
        string calldata signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external override {
        uint256 root = getRoot(groupId);
        uint8 depth = getDepth(groupId);

        if (root == 0) {
            root = getOffchainRoot(groupId);
            depth = getOffchainDepth(groupId);
        }

        require(depth != 0, "Interep: the group does not exist");

        IVerifier verifier = verifiers[depth];

        require(
            _isValidProof(signal, root, nullifierHash, externalNullifier, proof, verifier),
            "Interep: the proof is not valid"
        );

        // Prevent double-signaling (nullifierHash = hash(pollId + identityNullifier)).
        _saveNullifierHash(nullifierHash);

        emit ProofVerified(groupId, signal);
    }

    /// @dev See {IInterep-updateOffchainGroups}.
    function updateOffchainGroups(uint256[] calldata groupIds, OffchainGroup[] calldata groups)
        external
        override
        onlyOwner
    {
        require(groupIds.length == groups.length, "Interep: parameters lists does not have the same length");

        for (uint8 i = 0; i < groupIds.length; i++) {
            _updateOffchainGroup(groupIds[i], groups[i]);
        }
    }

    /// @dev See {IInterep-createGroup}.
    function createGroup(
        uint256 groupId,
        uint8 depth,
        address admin
    ) external override onlySupportedDepth(depth) {
        _createGroup(groupId, depth, 0);

        groupAdmins[groupId] = admin;

        emit GroupAdminUpdated(groupId, address(0), admin);
    }

    /// @dev See {IInterep-updateGroupAdmin}.
    function updateGroupAdmin(uint256 groupId, address newAdmin) external override onlyGroupAdmin(groupId) {
        groupAdmins[groupId] = newAdmin;

        emit GroupAdminUpdated(groupId, _msgSender(), newAdmin);
    }

    /// @dev See {IInterep-addMember}.
    function addMember(uint256 groupId, uint256 identityCommitment) external override onlyGroupAdmin(groupId) {
        _addMember(groupId, identityCommitment);
    }

    /// @dev See {IInterep-removeMember}.
    function removeMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external override onlyGroupAdmin(groupId) {
        _removeMember(groupId, identityCommitment, proofSiblings, proofPathIndices);
    }

    /// @dev See {IInterep-getOffchainRoot}.
    function getOffchainRoot(uint256 groupId) public view override returns (uint256) {
        return offchainGroups[groupId].root;
    }

    /// @dev See {IInterep-getOffchainDepth}.
    function getOffchainDepth(uint256 groupId) public view override returns (uint8) {
        return offchainGroups[groupId].depth;
    }

    /// @dev Updates an offchain group.
    /// @param groupId: Id of the group.
    /// @param group: Offchain data.
    function _updateOffchainGroup(uint256 groupId, OffchainGroup calldata group)
        private
        onlySupportedDepth(group.depth)
    {
        require(getDepth(groupId) == 0, "Interep: group id already exists onchain");

        offchainGroups[groupId] = group;

        emit OffchainGroupUpdated(groupId, group.root, group.depth);
    }
}
