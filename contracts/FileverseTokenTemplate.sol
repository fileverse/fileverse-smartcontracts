// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @custom:security-contact security@fileverse.io
contract FileverseTokenTemplate is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl, ERC721Burnable {
    using Counters for Counters.Counter;

    string public _baseUri = "";
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    constructor(
        string memory name,
        string memory symbol,
        address ownerAddress,
        string memory baseUri
    ) ERC721(name, symbol) {
        require(
            ownerAddress != address(0),
            "ownerAddress cannot be zero"
        );
        _baseUri = baseUri;
        _grantRole(DEFAULT_ADMIN_ROLE, ownerAddress);
        _grantRole(PAUSER_ROLE, ownerAddress);
        _grantRole(MINTER_ROLE, ownerAddress);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function safeBatchMint(address[] memory to) public onlyRole(MINTER_ROLE) returns (bool) {
        if(to.length < 1 || to.length > 50) return false;
        for (uint8 i = 0; i < to.length; i++){
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to[i], tokenId);
        }
        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
