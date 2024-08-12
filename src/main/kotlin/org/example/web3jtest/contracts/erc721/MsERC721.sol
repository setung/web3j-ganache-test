// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../openzeppelin/contracts/utils/Context.sol";
import "../openzeppelin/contracts/utils/Strings.sol";
import "../openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import "../openzeppelin/contracts/interfaces/IERC4906.sol";

abstract contract MsERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Errors, IERC4906 {
    using Strings for uint256;

    struct ContractMetadata {
        string name;
        string symbol;
    }

    struct TokenData {
        address owner;
        address approved;
        string tokenURI;
        bool isTransferable;
        uint256 price;
        bool forSale;
    }

    struct TokenOwnerData {
        uint256 balance;
        mapping(address => bool) operatorApprovals;
    }

    ContractMetadata private _metadata;

    mapping(uint256 tokenId => TokenData) private _tokens;

    mapping(address => TokenOwnerData) private _tokenOwners;

    constructor(string memory name_, string memory symbol_) {
        _metadata = ContractMetadata(name_, symbol_);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }
        return _tokenOwners[owner].balance;
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _requireOwned(tokenId);
    }

    function name() public view virtual returns (string memory) {
        return _metadata.name;
    }

    function symbol() public view virtual returns (string memory) {
        return _metadata.symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireOwned(tokenId);

        string memory _tokenURI = _tokens[tokenId].tokenURI;
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via string.concat).
        if (bytes(_tokenURI).length > 0) {
            return string.concat(base, _tokenURI);
        }

        return bytes(base).length > 0 ? string.concat(base, tokenId.toString()) : "";
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokens[tokenId].tokenURI = _tokenURI;
        emit MetadataUpdate(tokenId);
    }

    function getTransferable(uint256 tokenId) public view virtual returns (bool) {
        return _tokens[tokenId].isTransferable;
    }

    function setTransferable(uint256 tokenId, bool _transferable) public virtual returns (bool) {
        _tokens[tokenId].isTransferable = _transferable;
        return _transferable;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId, _msgSender());
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireOwned(tokenId);
        return _getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _tokenOwners[owner].operatorApprovals[operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual transferable(tokenId) {
        _transferFrom(from, to, tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal virtual {
         if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _tokens[tokenId].owner;
    }

    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        return _tokens[tokenId].approved;
    }

    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view virtual returns (bool) {
        return
            spender != address(0) &&
            (owner == spender || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view virtual {
        if (!_isAuthorized(owner, spender, tokenId)) {
            if (owner == address(0)) {
                revert ERC721NonexistentToken(tokenId);
            } else {
                revert ERC721InsufficientApproval(spender, tokenId);
            }
        }
    }

    function _increaseBalance(address account, uint128 value) internal virtual {
        unchecked {
           _tokenOwners[account].balance += value;
        }
    }

    function _update(address to, uint256 tokenId, address auth) internal virtual returns (address) {
        address from = _ownerOf(tokenId);

        if (auth != address(0)) {
            _checkAuthorized(from, auth, tokenId);
        }

        if (from != address(0)) {
            _approve(address(0), tokenId, address(0), false);

            unchecked {
               _tokenOwners[from].balance -= 1;
            }
        }

        if (to != address(0)) {
            unchecked {
                _tokenOwners[to].balance += 1;
            }
        }

        _tokens[tokenId].owner = to;

        emit Transfer(from, to, tokenId);

        return from;
    }

    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner != address(0)) {
            revert ERC721InvalidSender(address(0));
        }
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        _checkOnERC721Received(address(0), to, tokenId, data);
    }

    function _burn(uint256 tokenId) internal {
        address previousOwner = _update(address(0), tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        } else if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _safeTransfer(from, to, tokenId, "");
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    function _approve(address to, uint256 tokenId, address auth) internal {
        _approve(to, tokenId, auth, true);
    }

    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal virtual {
        if (emitEvent || auth != address(0)) {
            address owner = _requireOwned(tokenId);

            if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
                revert ERC721InvalidApprover(auth);
            }

            if (emitEvent) {
                emit Approval(owner, to, tokenId);
            }
        }

         _tokens[tokenId].approved = to;
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (operator == address(0)) {
            revert ERC721InvalidOperator(operator);
        }
        _tokenOwners[owner].operatorApprovals[operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireOwned(uint256 tokenId) internal view returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return owner;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    function listNft(uint256 tokenId, uint256 price) public {
        address owner = _requireOwned(tokenId);
        require(msg.sender == owner, "Only the owner can list the NFT");

        _tokens[tokenId].price = price;
        _tokens[tokenId].forSale = true;

        emit MetadataUpdate(tokenId);
    }

    function tradeNft(uint256 tokenId) public payable {
        require(_tokens[tokenId].forSale, "This NFT is not for sale");
        require(msg.value == _tokens[tokenId].price, "Insufficient funds to buy this NFT");
        
        address seller = _tokens[tokenId].owner;
        address buyer = msg.sender;

        _approve(buyer, tokenId, seller, true);
        _transferFrom(seller, buyer, tokenId);       
        _tokens[tokenId].forSale = false;
        payable(seller).transfer(msg.value);

        emit Transfer(seller, msg.sender, tokenId);
    }

    function isForSale(uint256 tokenId) public view returns(bool) {
        return _tokens[tokenId].forSale;
    }

    function getTokenPrice(uint256 tokenId) public view returns(uint256) {
        require(isForSale(tokenId), "This token is not for sales");
        return _tokens[tokenId].price;
    }

    modifier transferable(uint256 tokenId) {
        require( _tokens[tokenId].isTransferable, "This token is not transferable");
        _;
    }
}
