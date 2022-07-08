// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "solmate/tokens/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Creds is ERC20, Ownable {
    constructor(
        string memory names,
        string memory symbols,
        uint8 decimal
    ) ERC20(names, symbols, decimal) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address customer, uint256 amount) public onlyOwner {
        _burn(customer, amount);
    }

    function balanceOfCreds(address customer) public view returns (uint256) {
        return this.balanceOf(customer); //this is done to access the mapping balanceOf
    }
}
