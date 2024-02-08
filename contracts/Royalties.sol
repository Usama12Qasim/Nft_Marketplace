// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Royalties
{
    event Service_Fee_Calculations(address indexed Marketplace_Owner, uint256 Servicefee, uint256 NFTprice);
    event Royalties_Fee_Calculations(address indexed seller, uint256 RoyaltyFee_transfer, uint256 NFTprice);
    event Total_Fees_Calculations();

    function totalFeecalculations(uint256 _nftPrice, uint8 _serviceFee, address owner, address _seller, uint8 _royaltyFee) 
    internal  
    returns(uint256)
    {
        uint256 NFTprice = _nftPrice;
        uint256 Service_Calculations = serviceFee(_nftPrice, _serviceFee, owner);
        uint256  Royalty_Calculations = royaltyFee(_nftPrice, _royaltyFee, _seller);

        NFTprice = NFTprice - (Service_Calculations + Royalty_Calculations);
        payable(_seller).transfer(NFTprice);

        return NFTprice;
    }

    function serviceFee(uint256 _nftPrice, uint8 _serviceFee, address owner) internal returns(uint256)
    {
        uint256 amount = (_nftPrice * _serviceFee) / 100;
        payable(owner).transfer(amount);

        emit Service_Fee_Calculations(owner, amount,_nftPrice);
        return amount;
    }

    function royaltyFee(uint256 _nftprice, uint8 _royaltyFee, address _seller) internal returns(uint256)
    {
        uint256 amount = (_nftprice * _royaltyFee) / 100;
        payable(_seller).transfer(amount);

        emit Royalties_Fee_Calculations(_seller, amount, _nftprice);
        return amount;
    }
}