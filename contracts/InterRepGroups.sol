// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract InterRepGroups is Initializable, OwnableUpgradeable {
    /// @dev Emitted when a new root hash is added.
    /// @param _groupId: The id of the group.
    /// @param _identityCommitment: Semaphore identity commitment.
    /// @param _rootHash: The new root hash of the tree.
    event NewRootHash(bytes32 _groupId, uint256 _identityCommitment, uint256 _rootHash);

    mapping(bytes32 => uint256[]) public rootHashes;

    function initialize() public initializer {
        __Ownable_init();
    }

    /// @dev Add new .
    /// @param _groupId: The id of the group.
    /// @param _identityCommitment: Semaphore identity commitment.
    /// @param _rootHash: The new root hash of the tree.
    function addRootHash(
        bytes32 _groupId,
        uint256 _identityCommitment,
        uint256 _rootHash
    ) external onlyOwner {
        rootHashes[_groupId].push(_rootHash);

        emit NewRootHash(_groupId, _identityCommitment, _rootHash);
    }
}
