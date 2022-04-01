// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC721Template is AccessControl, Pausable, ERC721 {

    /// @dev Base token URI used as a prefix by tokenURI().
    string private _baseTokenURI;

    /// @dev Contract URI used for storefront-level metadata.
    string private _contractURI;

    mapping(address => bool) internal blackListAccounts;
    mapping(uint256 => bool) internal blackListTokenIds;

    uint256 public tokenIds;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    
    /**
     * @dev Emitted when the account is added to blacklist.
     */
    event BlackListAccount(address indexed account);

    /**
     * @dev Emitted when the account is removed from blacklist.
     */
    event UnblackListAccount(address indexed account);

    /**
     * @dev Emitted when the tokenId is added to blacklist.
     */
    event BlackListTokenId(uint256 indexed tokenId);

    /**
     * @dev Emitted when the tokenId is removed from blacklist.
     */
    event UnblackListTokenId(uint256 indexed tokenId);

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `OPERATOR_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC721-tokenURI}.
     */
    constructor(string memory name, string memory symbol, uint256 startTokenId, address owner) ERC721(name, symbol) {
        tokenIds = startTokenId;
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(MINTER_ROLE, owner);
        _setupRole(OPERATOR_ROLE, owner);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator or the contract owner.
     */
    function burn(uint256 tokenId) public virtual {
        require((_isApprovedOrOwner(_msgSender(), tokenId) || hasRole(DEFAULT_ADMIN_ROLE,_msgSender())), "burn: caller is not owner nor approved");
        _burn(tokenId);
    }


    function setBaseURI(string memory baseTokenURI) public onlyRole(OPERATOR_ROLE) {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

     function setContractURI(string memory contractURI_) public onlyRole(OPERATOR_ROLE) {
        _contractURI = contractURI_;
    }

    function contractURI() public view virtual returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function pause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function unpause() public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) public onlyRole(MINTER_ROLE) {
        _mint(to, tokenIds++);
    }

    function mintBatch(address to, uint256 count) public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < count; ++i) {
            _mint(to, tokenIds++);
        }
    }

    /// @notice Transfers the ownership of multiple NFTs from one address to another address
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param ids The NFTs to transfer
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids) public {
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            safeTransferFrom(from, to, id, "");
        }
    }

    /// @notice Transfers the ownership of multiple NFTs from one address to another address range [start, start + count)
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param start The NFT start tokenId
    /// @param count the NFT count
    function safeBatchTransferFrom(address from, address to, uint256 start, uint256 count) public {
        uint256 end = start + count;
        for (uint256 id = start; id < end; ++id) {
            safeTransferFrom(from, to, id, "");
        }
    }

    function remint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        require(tokenId < tokenIds, "Remint: tokenId must less than tokenIds");
        _mint(to, tokenId);
    }

    function blackListAccount(address account) public onlyRole(OPERATOR_ROLE) {
        blackListAccounts[account] = true;
        emit BlackListAccount(account);
    }

    function unblackListAccount(address account) public onlyRole(OPERATOR_ROLE) {
        blackListAccounts[account] = false;
        emit UnblackListAccount(account);
    }

    function blackListTokenId(uint256 tokenId) public onlyRole(OPERATOR_ROLE) {
        blackListTokenIds[tokenId] = true;
        emit BlackListTokenId(tokenId);
    }

    function unblackListTokenId(uint256 tokenId) public onlyRole(OPERATOR_ROLE) {
        blackListTokenIds[tokenId] = false;
        emit UnblackListTokenId(tokenId);
    }

    function blackListedAccount(address account) public view returns (bool) {
        return blackListAccounts[account];
    }

    function blackListedTokenId(uint256 tokenId) public view returns (bool) {
        return blackListTokenIds[tokenId];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        
        require(!paused(), "_beforeTokenTransfer: token transfer while paused");
        require(!blackListedAccount(from), "_beforeTokenTransfer: sender is blacklisted");
        require(!blackListedAccount(to), "_beforeTokenTransfer: recipient is blacklisted");
        require(!blackListedTokenId(tokenId), "_beforeTokenTransfer: tokenId is blacklisted");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdrawERC20(address tokenAddress, address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(to, balance);
    }

    function withdrawERC721(address tokenAddress, address to, uint256 tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC721(tokenAddress).transferFrom(address(this), to, tokenId);
    }
}