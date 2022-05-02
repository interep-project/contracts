// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IInterep.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@appliedzkp/semaphore-contracts/interfaces/IVerifier.sol";
import "@appliedzkp/semaphore-contracts/base/SemaphoreCore.sol";
import "@appliedzkp/semaphore-contracts/base/SemaphoreConstants.sol";

/// @title Interep
/// @dev Interep is a collection of reputation Semaphore groups in which members
/// can prove their Web2 reputation (or their membership in a group) without revealing their identity.
/// Each Interep group is actually a Merkle tree, whose leaves represent the members of the group.
/// Interep groups are saved off-chain but the Merkle tree roots of those groups are saved on-chain
/// at regular intervals, so that users can verify their Semaphore ZK proof on-chain with this contract.
contract Interep is IInterep, Ownable, SemaphoreCore {
    /// @dev Gets a tree depth and returns its verifier address.
    mapping(uint8 => IVerifier) public verifiers;

    /// @dev Gets a group id and returns the group data.
    mapping(uint256 => Group) public groups;

    /// @dev Checks if there is a verifier for the given tree depth.
    /// @param depth: Depth of the tree.
    modifier onlySupportedDepth(uint8 depth) {
        require(address(verifiers[depth]) != address(0), "Interep: tree depth is not supported");
        _;
    }

    /// @dev Initializes the Semaphore verifiers used to verify the user's ZK proofs.
    /// @param _verifiers: List of Semaphore verifiers (address and related Merkle tree depth).
    constructor(Verifier[] memory _verifiers) {
        for (uint8 i = 0; i < _verifiers.length; i++) {
            verifiers[_verifiers[i].merkleTreeDepth] = IVerifier(_verifiers[i].contractAddress);
        }
    }

    /// @dev See {IInterep-updateGroups}.
    function updateGroups(Group[] calldata _groups) external override onlyOwner {
        for (uint8 i = 0; i < _groups.length; i++) {
            uint256 groupId = uint256(keccak256(abi.encodePacked(_groups[i].provider, _groups[i].name))) %
                SNARK_SCALAR_FIELD;

            _updateGroup(groupId, _groups[i]);
        }
    }

    /// @dev See {IInterep-verifyProof}.
    function verifyProof(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external override {
        uint256 root = getRoot(groupId);
        uint8 depth = getDepth(groupId);

        require(depth != 0, "Interep: group does not exist");

        IVerifier verifier = verifiers[depth];

        _verifyProof(signal, root, nullifierHash, externalNullifier, proof, verifier);

        _saveNullifierHash(nullifierHash);

        emit ProofVerified(groupId, signal);
    }

    /// @dev See {IInterep-getRoot}.
    function getRoot(uint256 groupId) public view override returns (uint256) {
        return groups[groupId].root;
    }

    /// @dev See {IInterep-getDepth}.
    function getDepth(uint256 groupId) public view override returns (uint8) {
        return groups[groupId].depth;
    }

    /// @dev Updates an Interep group.
    /// @param groupId: Id of the group.
    /// @param group: Group data.
    function _updateGroup(uint256 groupId, Group calldata group) private onlySupportedDepth(group.depth) {
        groups[groupId] = group;

        emit GroupUpdated(groupId, group.provider, group.name, group.root, group.depth);
    }
}
