// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract InterRepGroups is Initializable, OwnableUpgradeable {
    /// @dev Emitted when a new root hash is added.
    /// @param _provider: The provider of the group.
    /// @param _name: The name of the group.
    /// @param _identityCommitment: Semaphore identity commitment.
    /// @param _rootHash: The new root hash of the tree.
    event NewRootHash(bytes32 indexed _provider, bytes32 indexed _name, uint256 _identityCommitment, uint256 _rootHash);

    /// @dev Gets a group id and returns the last root hash.
    mapping(bytes32 => uint256) private rootHashes;

    function initialize() public initializer {
        __Ownable_init();
    }

    /// @dev Associates the new root hash with its group id (keccak256(provider + name)).
    /// @param _provider: the provider of the group.
    /// @param _name: the name of the group.
    /// @param _identityCommitment: semaphore identity commitment.
    /// @param _rootHash: the new root hash of the tree.
    function addRootHash(
        bytes32 _provider,
        bytes32 _name,
        uint256 _identityCommitment,
        uint256 _rootHash
    ) external onlyOwner {
        rootHashes[keccak256(abi.encodePacked(_provider, _name))] = _rootHash;

        emit NewRootHash(_provider, _name, _identityCommitment, _rootHash);
    }

    /// @dev Associates new root hashes with their group ids (keccak256(provider + name)).
    /// @param _provider: the provider of the group.
    /// @param _names: the names of the group.
    /// @param _identityCommitments: semaphore identity commitments.
    /// @param _rootHashes: the new root hashes of the tree.
    function batchAddRootHash(
        bytes32 _provider,
        bytes32[] memory _names,
        uint256[] memory _identityCommitments,
        uint256[] memory _rootHashes
    ) external onlyOwner {
        require(
            _names.length == _identityCommitments.length && _names.length == _rootHashes.length,
            "Array parameters should have the same length"
        );

        for (uint256 i = 0; i < _names.length; i++) {
            rootHashes[keccak256(abi.encodePacked(_provider, _names[i]))] = _rootHashes[i];

            emit NewRootHash(_provider, _names[i], _identityCommitments[i], _rootHashes[i]);
        }
    }

    /// @dev Gets a group provider and a group name and returns the last root hash of the group.
    /// @return The root hash.
    function getRootHash(bytes32 _provider, bytes32 _name) external view returns (uint256) {
        return rootHashes[keccak256(abi.encodePacked(_provider, _name))];
    }
}
