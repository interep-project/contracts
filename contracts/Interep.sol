// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IInterep.sol";
import "./InterepGroups.sol";
import "@appliedzkp/semaphore-contracts/interfaces/IVerifier.sol";
import "@appliedzkp/semaphore-contracts/base/SemaphoreCore.sol";

/// @title Interep
/// @dev Interep is a collection of groups (onchain and offchain) where members can prove
/// their membership without revealing their identity. DApps can use this contract to verify
/// if a Semaphore proof is valid and then use its signal.
contract Interep is IInterep, SemaphoreCore, InterepGroups {
    /// @dev Gets a tree depth and returns its verifier address.
    mapping(uint8 => IVerifier) public verifiers;

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
    ) public override {
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
}
