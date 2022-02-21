//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// @title Interep interface.
/// @dev Interface of a Interep contract.
interface IInterep {
    /// @dev Emitted when a Semaphore proof is verified.
    /// @param groupId: Id of the group.
    /// @param signal: Semaphore signal.
    event ProofVerified(uint256 indexed groupId, string signal);

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
}
