// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

//CREDIT NFT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error NotCurrentHolder();
error AmountExceedsDepositValue();

contract ETHCredit is ERC721("Ethereum CREDIT", "eCREDIT"), Ownable {
    uint256 private _tokenId;

    struct CreditValue {
        uint256 depositValue;
        uint256 creationTime;
    }

    //NFTID => value stored in NFT
    mapping(uint256 => CreditValue) public creditValue;

    event SubtractValue(
        address indexed customer,
        uint256 tokenId,
        uint256 amount
    );
    event Deleted(address indexed customer, uint256 tokenId, uint256 value);

    //core
    function createCREDIT(address customer, uint256 amount) public onlyOwner {
        creditValue[_tokenId].depositValue = amount;
        creditValue[_tokenId].creationTime = block.number;
        _mint(customer, _tokenId);
        unchecked {
            ++_tokenId;
        }
    }

    /*customer cannot withdraw more than depositValue
    because it will throw Arithmetic over/underflow error
    */
    function subtractValueFromCREDIT(
        address customer,
        uint256 tokenId,
        uint256 amount
    ) public onlyOwner {
        address currentHolder = ERC721.ownerOf(tokenId);
        if (currentHolder != customer) revert NotCurrentHolder();
        creditValue[_tokenId].depositValue -= amount;
        emit SubtractValue(customer, tokenId, amount);
    }

    function deleteCREDIT(address customer, uint256 tokenId)
        public
        onlyOwner
        returns (uint256 value)
    {
        address currentHolder = ERC721.ownerOf(tokenId);
        if (currentHolder != customer) revert NotCurrentHolder();
        value = balanceOfCredit(tokenId);
        delete creditValue[tokenId];
        _burn(tokenId);
        emit Deleted(customer, tokenId, value);
        return value;
    }

    function balanceOfCredit(uint256 tokenId) public view returns (uint256) {
        return creditValue[tokenId].depositValue;
    }

    function timeOfCredit(uint256 tokenId) public view returns (uint256) {
        return creditValue[tokenId].creationTime;
    }
}