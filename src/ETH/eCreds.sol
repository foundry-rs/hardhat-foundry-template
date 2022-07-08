// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ECreds is ERC20("Ethereum Credits", "eCreds"), Ownable {
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address customer, uint256 amount) public onlyOwner {
        _burn(customer, amount);
    }
}
