// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CryptoHeroesNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public HERO_CREATION_LIMIT = 30;

    constructor() ERC721("Heroes", "HERO") {}

    function addItem(address _to, string memory _uri)
        public
        onlyOwner
        returns (uint256)
    {
        require(_tokenIds.current() < HERO_CREATION_LIMIT);
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _safeMint(_to, newItemId);
        _setTokenURI(newItemId, _uri);

        return newItemId;
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
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
}
