// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

//CREDIT NFT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Credit is ERC721, Ownable {
    error NotCurrentHolder();
    error AmountExceedsDepositValue();

    uint256 public _tokenId;

    mapping(uint256 => uint256) public depositValue;

    event AddValue(uint256 tokenId, uint256 amount);
    event SubtractValue(
        address indexed customer,
        uint256 tokenId,
        uint256 amount
    );
    event Deleted(address indexed customer, uint256 tokenId, uint256 value);

    constructor(string memory names, string memory symbols)
        ERC721(names, symbols)
    {}

    //core
    function createCREDIT(address customer, uint256 amount) public onlyOwner {
        uint256 tokenId = ++_tokenId;
        depositValue[tokenId] = amount;
        _safeMint(customer, tokenId);
    }

    function addValueToCREDIT(
        address customer,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        address currentHolder = ERC721.ownerOf(tokenId);
        if (currentHolder != customer) revert NotCurrentHolder();
        depositValue[tokenId] += amount;
        emit AddValue(tokenId, amount);
    }

    function subtractValueFromCREDIT(
        address customer,
        uint256 tokenId,
        uint256 amount
    ) public onlyOwner {
        address currentHolder = ERC721.ownerOf(tokenId);
        if (currentHolder != customer) revert NotCurrentHolder();
        if (amount >= depositValue[tokenId]) revert AmountExceedsDepositValue();
        depositValue[tokenId] -= amount;
        emit SubtractValue(customer, tokenId, amount);
    }

    function deleteCREDIT(address customer, uint256 tokenId)
        public
        onlyOwner
        returns (uint256 value)
    {
        address currentHolder = ERC721.ownerOf(tokenId);
        if (currentHolder != customer) revert NotCurrentHolder();
        value = depositValue[tokenId];
        delete depositValue[tokenId];
        _burn(tokenId);
        emit Deleted(customer, tokenId, value);
        return value;
    }

    function balanceOfCredit() public {}
}
