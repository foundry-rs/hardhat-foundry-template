// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ICREDS.sol";
import "../interfaces/ICREDIT.sol";

error EmptySend();

contract TokenManagerETH is Ownable, Pausable, ReentrancyGuard {
    using SafeTransferLib for address;

    ICREDS public creds;
    ICREDIT public credit;

    uint256 public globalDepositValue;

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);
    event SubtractFromCredit(
        address indexed customer,
        uint256 tokenId,
        uint256 amount
    );

    constructor(ICREDS _creds, ICREDIT _credit) {
        creds = _creds;
        credit = _credit;
    }

    function deposit() public payable whenNotPaused nonReentrant {
        if (msg.value == 0) revert EmptySend();

        address customer = msg.sender;
        uint256 amount = msg.value;
        globalDepositValue += amount;
        creds.mint(customer, amount);
        credit.createCREDIT(customer, amount);
        emit Deposit(customer, amount);
    }

    function partialWithdraw(uint256 tokenId, uint256 amount)
        public
        whenNotPaused
        nonReentrant
    {
        address customer = msg.sender;
        creds.burn(customer, amount);
        credit.subtractValueFromCREDIT(customer, tokenId, amount);
        globalDepositValue -= amount;
        customer.safeTransferETH(amount);
        emit SubtractFromCredit(customer, tokenId, amount);
    }

    function claimAllUnderlying(uint256 tokenId)
        public
        whenNotPaused
        nonReentrant
    {
        address customer = msg.sender;
        uint256 amount = credit.deleteCREDIT(customer, tokenId);
        globalDepositValue -= amount;
        creds.burn(customer, amount);
        customer.safeTransferETH(amount);
        emit Withdrawal(customer, amount);
    }

    receive() external payable {
        //put emit here to track this
        deposit();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
