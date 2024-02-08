// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";

contract MyToken is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Pausable {
    uint256 private _nextTokenId = 1;
    address owner;
    address Marketplace;
    uint8 Max_Royalty_Amount;

    mapping(uint256 => uint8) Royalty_Percentage;

    event Nft_Info(address indexed to, uint256 tokenId, string Uri, uint8 RoyaltyAmount);


    modifier onlyOwner()
    {
        require(msg.sender == owner, "you are not the owner");
        _;
    }

    modifier onlyMarkerplaceOwner() 
    {
        require(msg.sender == Marketplace, "You have not the access!");
        _;
    }

    constructor()
        ERC721("MyToken", "MTK"){}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mintNFT(address _to, string memory _uri, uint8 _royaltyAmount) external
    {
        require(_royaltyAmount >= Max_Royalty_Amount,
        "Royalty fee is not according to the Marketplace");

        safeMint(_to, _uri, _royaltyAmount);
        setApprovalForAll(Marketplace, true);
    }

    function safeMint(address to, string memory uri, uint8 _royaltyAmount) internal {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        Royalty_Percentage[tokenId] = _royaltyAmount;

        emit Nft_Info(to, tokenId, uri, _royaltyAmount);
    }

    function setMarketplaceAddress(address _marketplace) external onlyOwner
    {
        Marketplace = _marketplace;
    }

    function setRoyaltyPercentage(uint8 _royaltyfee) external onlyMarkerplaceOwner
    {
        Max_Royalty_Amount = _royaltyfee;
    }

    function getRoyalty(uint256 _tokenId) external view returns(uint8)
    {
        return Royalty_Percentage[_tokenId];
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
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
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
