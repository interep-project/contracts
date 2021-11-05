// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IncrementalTree, TreeData} from "./IncrementalTree.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Groups is Initializable, OwnableUpgradeable {
    using IncrementalTree for TreeData;

    /// @dev Emitted when a new group is created.
    /// @param provider: The provider of the group.
    /// @param name: The name of the group.
    /// @param depth: The depth of the tree.
    event NewGroup(bytes32 indexed provider, bytes32 name, uint8 depth);

    /// @dev Emitted when a new identity commitment is added.
    /// @param provider: The provider of the group.
    /// @param name: The name of the group.
    /// @param identityCommitment: The new identity commitment.
    /// @param rootHash: The new root hash of the tree.
    event NewIdentityCommitment(
        bytes32 indexed provider,
        bytes32 indexed name,
        uint256 identityCommitment,
        uint256 rootHash
    );

    /// @dev Gets a group id and returns the group/tree data.
    mapping(bytes32 => TreeData) private groups;

    /// @dev Gets a group id and returns the last root hash.
    mapping(bytes32 => uint256) private rootHashes;

    function initialize() public initializer {
        __Ownable_init();
    }

    /// @dev ...
    /// @param provider: The provider of the group.
    /// @param name: The name of the group.
    /// @param depth: Depth of the tree.
    function createGroup(
        bytes32 provider,
        bytes32 name,
        uint8 depth
    ) external onlyOwner {
        bytes32 groupId = getGroupId(provider, name);

        require(groups[groupId].depth == 0, "The group already exists");

        groups[groupId].init(depth, 0);

        emit NewGroup(provider, name, depth);
    }

    /// @dev ...
    /// @param provider: The provider of the group.
    /// @param names: The names of the group.
    /// @param identityCommitments: Identity commitments.
    function batchAddIdentityCommitment(
        bytes32 provider,
        bytes32[] memory names,
        uint256[] memory identityCommitments
    ) external onlyOwner {
        require(names.length == identityCommitments.length, "Array parameters should have the same length");

        for (uint256 i = 0; i < names.length; i++) {
            addIdentityCommitment(provider, names[i], identityCommitments[i]);
        }
    }

    /// @dev Gets a group provider and a group name and returns the last root hash of the group.
    /// @return The root hash.
    function getRootHash(bytes32 provider, bytes32 name) external view returns (uint256) {
        bytes32 groupId = getGroupId(provider, name);

        return rootHashes[groupId];
    }

    /// @dev ...
    /// @param provider: The provider of the group.
    /// @param name: The name of the group.
    /// @param identityCommitment: The new identity commitment.
    function addIdentityCommitment(
        bytes32 provider,
        bytes32 name,
        uint256 identityCommitment
    ) public onlyOwner {
        bytes32 groupId = getGroupId(provider, name);

        require(groups[groupId].depth != 0, "The group does not exist");

        uint256 rootHash = groups[groupId].insert(identityCommitment);

        rootHashes[groupId] = rootHash;

        emit NewIdentityCommitment(provider, name, identityCommitment, rootHash);
    }

    function getGroupId(bytes32 provider, bytes32 name) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(provider, name));
    }
}
