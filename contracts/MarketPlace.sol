// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFT.sol";
import "./Royalties.sol";

contract NFT_MarketPlace is Royalties {
    enum SalesChoice {
        notOnSale,
        onFixedRates,
        onAuction
    }
    SalesChoice currentStatus;

    struct NFT_Info {
        address seller;
        address NFT_Contract;
        uint256 tokenId;
        uint256 NFT_price;
        address[] bidderAddress;
        uint256[] bidderAmount;
        uint256 startTime;
        uint256 endTime;
        bool isListed;
        SalesChoice currentChoice;
    }

    mapping(address => NFT_Info) mappingNFT_Info;

    event BuyNft(uint256 TokenId, address NFtcontract, uint256 NFTprice);
    event ListNFT_fixedRates(
        uint256 tokenId,
        address NFtcontract,
        uint256 NFt_Price,
        address NFT_Owner
    );
    event ListNFT_ForAuctions(
        uint256 tokenId,
        address NFtcontract,
        uint256 NFt_Price,
        address NFT_Owner,
        uint256 startTime,
        uint256 endTime
    );
    event HighestBidsReceived(address indexed HighestAddress, uint256 HighestBids);
    event transferNFT(
        address indexed Marketplace,
        address Buyer,
        uint256 TokenId
    );
    event UnlistNFT();
    event MarketplaceWalletInfo(
        uint8 ServiceFees,
        uint8 Max_Royalty_Amount,
        address NFT_contract
    );

    address owner;
    address MarketPlace_Wallet;
    uint8 Marketplace_ServiceFee;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the Owner");
        _;
    }

    modifier notonSale(address _seller) {
        require(
            mappingNFT_Info[_seller].currentChoice == SalesChoice.notOnSale,
            "Nft is already listed"
        );
        _;
    }

    modifier OnAuction(address _seller) {
        require(
            mappingNFT_Info[_seller].currentChoice == SalesChoice.onAuction,
            "Nft is NOT avaialble for AUCTION"
        );
        _;
    }

    modifier OnFixedRates(address _seller) {
        require(
            mappingNFT_Info[_seller].currentChoice == SalesChoice.onFixedRates,
            "Nft is NOT avaialble for Fixed RATES"
        );
        _;
    }

    function setMarketplaceWallet(
        address _wallet,
        uint8 _servicefee,
        uint8 _royaltyPercentage,
        address _nftContract
    ) external onlyOwner {
        MyToken nftcontract = MyToken(_nftContract);
        nftcontract.setRoyaltyPercentage(_royaltyPercentage);
        MarketPlace_Wallet = _wallet;
        Marketplace_ServiceFee = _servicefee;

        emit MarketplaceWalletInfo(
            _servicefee,
            _royaltyPercentage,
            _nftContract
        );
    }

    function ListNFt_FixedRates(
        uint256 _tokenId,
        address _nftContract,
        uint256 _nftprice
    ) external {
        MyToken nftcontract = MyToken(_nftContract);

        require(
            nftcontract.ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );

        require(
            !mappingNFT_Info[nftcontract.ownerOf(_tokenId)].isListed,
            "Already Listed"
        );

        NFT_Info storage Listing = mappingNFT_Info[msg.sender];
        Listing.NFT_Contract = _nftContract;
        Listing.NFT_price = _nftprice;
        Listing.tokenId = _tokenId;
        Listing.seller = msg.sender;
        Listing.isListed = true;
        Listing.currentChoice = SalesChoice(1);

        _transferNFT_ToMarketplace(_tokenId, _nftContract);

        emit ListNFT_fixedRates(
            _tokenId,
            _nftContract,
            _nftprice,
            nftcontract.ownerOf(_tokenId)
        );
    }

    function unlistNFT(
        uint256 _tokenId,
        address _nftContract
    ) external onlyOwner {
        MyToken nftcontract = MyToken(_nftContract);
        require(
            mappingNFT_Info[nftcontract.ownerOf(_tokenId)].isListed,
            "NFT is not Listed"
        );

        nftcontract.safeTransferFrom(
            address(this),
            mappingNFT_Info[msg.sender].seller,
            _tokenId
        );

        delete mappingNFT_Info[msg.sender];
    }

    function ListNFt_onAuction(
        uint256 _tokenId,
        address _nftContract,
        uint256 _nftprice,
        uint256 _endTime
    ) external {
        MyToken nftcontract = MyToken(_nftContract);

        require(
            nftcontract.ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );

        require(
            !mappingNFT_Info[nftcontract.ownerOf(_tokenId)].isListed,
            "Already Listed"
        );

        NFT_Info storage Listing = mappingNFT_Info[msg.sender];
        Listing.NFT_Contract = _nftContract;
        Listing.NFT_price = _nftprice;
        Listing.tokenId = _tokenId;
        Listing.startTime = block.timestamp;
        Listing.endTime = _endTime;
        Listing.seller = msg.sender;
        Listing.isListed = true;
        Listing.currentChoice = SalesChoice(1);

        _transferNFT_ToMarketplace(_tokenId, _nftContract);

        emit ListNFT_ForAuctions(
            _tokenId,
            _nftContract,
            _nftprice,
            nftcontract.ownerOf(_tokenId),
            block.timestamp,
            _endTime
        );
    }

    function addBids(
        uint256 _tokenId,
        uint256 _bids,
        address _seller,
        address _nftContract
    ) external payable OnAuction(mappingNFT_Info[_seller].seller) {
        MyToken nftcontract = MyToken(_nftContract);

        require(
            nftcontract.ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );

        require(
            mappingNFT_Info[_seller].seller != msg.sender,
            "Can't self bid"
        );

        require(
            block.timestamp < mappingNFT_Info[_seller].endTime,
            "Auction time is over"
        );

        uint minAmount = getHighestBid(_seller);

        require(
            _bids > minAmount && msg.value == _bids,
            "Bids must be greater than last bid"
        );

        uint256 lastBidAmount = mappingNFT_Info[_seller].bidderAmount[
            (mappingNFT_Info[_seller].bidderAmount.length) - 1
        ];

        address lastHighestAddress = mappingNFT_Info[_seller].bidderAddress[
            mappingNFT_Info[_seller].bidderAddress.length - 1
        ];

        require(_bids > lastBidAmount, "bid must be greater than last bid");

        payable(lastHighestAddress).transfer(lastBidAmount);

        mappingNFT_Info[_seller].bidderAddress.push(msg.sender);
        mappingNFT_Info[_seller].bidderAmount.push(_bids);

        emit HighestBidsReceived(lastHighestAddress, lastBidAmount);
    }

    function claimNFT(uint256 _tokenId, address _nftcontract, address _seller) external
    {
        require(mappingNFT_Info[_seller].bidderAddress.length != 0,
        "no bids received");

        address HighestBidAddress = getHighestBidderAddress(_seller);

        require(HighestBidAddress == msg.sender,
        "Caller is not the highest bidder");

        _claimNFT(_tokenId, _nftcontract, _seller);

    }

    function _claimNFT(uint256 _tokenId, address _nftcontract, address _seller) internal
    {
        MyToken nftcontract = MyToken(_nftcontract);
        uint256 HighestBidAmount = getHighestBid(_seller);
        address HighestBidAddress = getHighestBidderAddress(_seller);

        if(HighestBidAddress != address(0))
        {
            _transferNft(
            _tokenId,
            _nftcontract,
            nftcontract.ownerOf(_tokenId),
            HighestBidAddress,
            HighestBidAmount
        );
        }

        delete mappingNFT_Info[_seller];
        
    }

    function getHighestBid(address _seller) public view returns (uint256) {
        if (mappingNFT_Info[_seller].bidderAddress.length == 0) {
            return mappingNFT_Info[_seller].NFT_price;
        } else {
            uint256 currentHighestBid = mappingNFT_Info[_seller].bidderAmount[
                (mappingNFT_Info[_seller].bidderAmount.length) - 1
            ];

            return currentHighestBid;
        }
    }

    function getHighestBidderAddress(
        address _seller
    ) public view returns (address) {
        require(
            block.timestamp > mappingNFT_Info[_seller].endTime,
            "Auction is not over"
        );

        if (mappingNFT_Info[_seller].bidderAddress.length != 0) {
            address currentHighestAddress = mappingNFT_Info[_seller]
                .bidderAddress[
                    mappingNFT_Info[_seller].bidderAddress.length - 1
                ];

            return currentHighestAddress;
        } else {
            return address(0);
        }
    }

    function buyNFT(
        uint256 _tokenId,
        uint256 _nftPrice,
        address _nftcontract,
        address _seller
    ) external payable {
        MyToken nftcontract = MyToken(_nftcontract);

        require(nftcontract.ownerOf(_tokenId) != msg.sender, "Cannot self Buy");

        require(msg.value == _nftPrice, "InSufficient Amount");

        _transferNft(
            _tokenId,
            _nftcontract,
            nftcontract.ownerOf(_tokenId),
            msg.sender,
            _nftPrice
        );

        emit BuyNft(_tokenId, _nftcontract, _nftPrice);

        delete mappingNFT_Info[_seller];
    }

    function _transferNft(
        uint256 _tokenId,
        address _nftContract,
        address _seller,
        address _buyerAddress,
        uint256 _nftPrice
    ) internal {
        MyToken nftcontract = MyToken(_nftContract);

        totalFeecalculations(
            _nftPrice,
            Marketplace_ServiceFee,
            address(this),
            _seller,
            nftcontract.getRoyalty(_tokenId)
        );

        nftcontract.safeTransferFrom(address(this), _buyerAddress, _tokenId);
        nftcontract.approve(_buyerAddress, _tokenId);
        nftcontract.setApprovalForAll(_buyerAddress, true);

        emit transferNFT(address(this), msg.sender, _tokenId);
    }

    function _transferNFT_ToMarketplace(
        uint256 _tokenId,
        address _nftContract
    ) internal {
        MyToken nftcontract = MyToken(_nftContract);
        nftcontract.safeTransferFrom(
            nftcontract.ownerOf(_tokenId),
            address(this),
            _tokenId
        );
    }
}
