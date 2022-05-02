//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Interep interface.
/// @dev Interface of a Interep contract.
interface IInterep {
    struct Verifier {
        address contractAddress;
        uint8 merkleTreeDepth;
    }

    struct Group {
        bytes32 provider;
        bytes32 name;
        uint256 root;
        uint8 depth;
    }

    /// @dev Emitted when a Semaphore proof is verified.
    /// @param groupId: Id of the group.
    /// @param signal: Semaphore signal.
    event ProofVerified(uint256 indexed groupId, bytes32 signal);

    /// @dev Emitted when an Interep group is updated.
    /// @param groupId: Id of the group.
    /// @param provider: Provider of the group.
    /// @param name: Name of the group.
    /// @param root: Root hash of the tree.
    /// @param depth: Depth of the tree.
    event GroupUpdated(
        uint256 groupId,
        bytes32 indexed provider,
        bytes32 indexed name,
        uint256 root,
        uint8 indexed depth
    );

    /// @dev Updates the Interep groups.
    /// @param groups: List of Interep groups.
    function updateGroups(Group[] calldata groups) external;

    /// @dev Saves the nullifier hash to avoid double signaling and emits an event
    /// if the zero-knowledge proof is valid.
    /// @param groupId: Id of the group.
    /// @param signal: Semaphore signal.
    /// @param nullifierHash: Nullifier hash.
    /// @param externalNullifier: External nullifier.
    /// @param proof: Zero-knowledge proof.
    function verifyProof(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external;

    /// @dev Returns the root hash of an Interep group.
    /// @param groupId: Id of the group.
    /// @return Root hash of the group.
    function getRoot(uint256 groupId) external view returns (uint256);

    /// @dev Returns the tree depth of an Interep group.
    /// @param groupId: Id of the group.
    /// @return Tree depth of the group.
    function getDepth(uint256 groupId) external view returns (uint8);
}
