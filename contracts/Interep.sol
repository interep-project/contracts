// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@appliedzkp/semaphore-contracts/base/SemaphoreGroups.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Interep groups.
contract Interep is Ownable, SemaphoreGroups {
    /// @dev Emitted when an offchain group is updated. It is useful to ensure the
    /// integrity of the offchain group trees.
    /// @param provider: Provider of the group.
    /// @param name: Name of the group.
    /// @param root: New root hash of the tree.
    event OffchainRoot(bytes32 indexed provider, bytes32 indexed name, uint256 root);

    /// @dev Gets a group id and returns the offchain tree root.
    mapping(uint256 => uint256) private offchainRoots;

    /// @dev Gets a group id and returns the group admin address.
    mapping(uint256 => address) private groupAdmins;

    /// @dev Adds a list of new offchain root hashes.
    /// @param providers: Providers of the groups.
    /// @param names: Names of the groups.
    /// @param roots: New root hashes of the trees.
    function addOffchainRoots(
        bytes32[] calldata providers,
        bytes32[] calldata names,
        uint256[] calldata roots
    ) external onlyOwner {
        require(
            providers.length == names.length && names.length == roots.length,
            "Groups: parameters lists does not have the same length"
        );

        for (uint8 i = 0; i < providers.length; i++) {
            uint256 groupId = createOffchainGroupId(providers[i], names[i]);

            offchainRoots[groupId] = roots[i];

            emit OffchainRoot(providers[i], names[i], roots[i]);
        }
    }

    /// @dev Creates a new group.
    /// @param groupId: Id of the group.
    /// @param depth: Depth of the tree.
    /// @param admin: Admin of the group.
    function createGroup(
        uint256 groupId,
        uint8 depth,
        address admin
    ) external {
        _createGroup(groupId, depth);

        groupAdmins[groupId] = admin;
    }

    /// @dev Adds a new member to an existing group.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: New identity commitment.
    function addMember(uint256 groupId, uint256 identityCommitment) external {
        require(groupAdmins[groupId] == _msgSender(), "Interep: caller is not the group admin");

        _addMember(groupId, identityCommitment);
    }

    /// @dev Removes a member from an existing group. A proof of membership is
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
    ) external {
        require(groupAdmins[groupId] == _msgSender(), "Interep: caller is not the group admin");

        _removeMember(groupId, identityCommitment, proofSiblings, proofPathIndices);
    }

    /// @dev Returns the last root hash of an offchain group.
    /// @param provider: Provider of the group.
    /// @param name: Name of the group.
    /// @return Root hash of the group.
    function getOffchainRoot(bytes32 provider, bytes32 name) external view returns (uint256) {
        uint256 groupId = createOffchainGroupId(provider, name);

        return offchainRoots[groupId];
    }

    /// @dev Creates an offchain group id.
    /// @param provider: Provider of the group.
    /// @param name: Name of the group.
    /// @return Group id.
    function createOffchainGroupId(bytes32 provider, bytes32 name) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(provider, name)));
    }
}
