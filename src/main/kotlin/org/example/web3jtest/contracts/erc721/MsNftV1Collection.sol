// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../openzeppelin/contracts/access/Ownable.sol";
import "./MsERC721.sol";

contract MsNftV1Collection is MsERC721, Ownable {

    uint256 private _tokenId = 0;

    event Mint();

    constructor(address initialOwner, string memory name, string memory symbol) MsERC721(name, symbol) Ownable(initialOwner) {
    }

    function mint(address to, string memory metadataUrl) public onlyOwner{
        _mint(to, metadataUrl);
        emit Mint();
    }

    function mint(address[] memory to, string[] memory metadataUrl) external onlyOwner{
        require(to.length == metadataUrl.length);
        
        for(uint256 i = 0; i < to.length; i++) {
           _mint(to[i], metadataUrl[i]);
        }
        emit Mint();
    }

    function mint(address[] memory to, string memory metadataUrl) external onlyOwner{
        for(uint256 i = 0; i < to.length; i++) {
           _mint(to[i], metadataUrl);
        }
        emit Mint();
    }

    function _mint(address to, string memory metadataUrl) internal onlyOwner{
        uint256 tokenId = _tokenId++;
        _mint(to, tokenId);
        _setTokenURI(tokenId, metadataUrl);
    }

    function setTokenURI(uint256 tokenId, string memory metadataUrl) external onlyOwner{
        _setTokenURI(tokenId, metadataUrl);
    }

    function exchangeNewToken(address to, uint256 tokenId, string memory metadataUrl) external onlyOwner {
        require(ownerOf(tokenId) == to);
        _burn(tokenId);
        _mint(to, metadataUrl);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}