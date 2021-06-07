// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract Badge is ERC721, Pausable, Ownable, ERC721Burnable {
    address private _backendAddress;
    string private _baseTokenURI;

    struct MintParameters {
        address to;
        uint256 tokenId;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address backendAddress_
    ) ERC721(name_, symbol_) {
        _backendAddress = backendAddress_;
    }

    modifier onlyBackend {
        require(msg.sender == _backendAddress, "Unauthorized");
        _;
    }

    function batchMint(MintParameters[] memory tokensToMint) external onlyBackend {
        for (uint256 i = 0; i < tokensToMint.length; i++) {
            _mint(tokensToMint[i].to, tokensToMint[i].tokenId);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId) public onlyBackend {
        _safeMint(to, tokenId);
    }

    function changeBackendAddress(address backendAddress) public onlyOwner {
        _backendAddress = backendAddress;
    }

    function changeBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
