// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ICREDS.sol";
import "../interfaces/ICREDIT.sol";

error EmptySend();

contract TokenManagerETH is ReentrancyGuard {
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

    function deposit() external payable nonReentrant {
        if (msg.value == 0) revert EmptySend();

        address customer = msg.sender;
        uint256 amount = msg.value;
        globalDepositValue += amount;
        creds.mint(customer, amount);
        credit.createCREDIT(customer, amount);
        emit Deposit(customer, amount);
    }

    function partialWithdraw(uint256 tokenId, uint256 amount)
        external
        nonReentrant
    {
        address customer = msg.sender;
        creds.burn(customer, amount);
        credit.subtractValueFromCREDIT(customer, tokenId, amount);
        globalDepositValue -= amount;
        customer.safeTransferETH(amount);
        emit SubtractFromCredit(customer, tokenId, amount);
    }

    function claimAllUnderlying(uint256 tokenId) external nonReentrant {
        address customer = msg.sender;
        uint256 amount = credit.deleteCREDIT(customer, tokenId);
        globalDepositValue -= amount;
        creds.burn(customer, amount);
        customer.safeTransferETH(amount);
        emit Withdrawal(customer, amount);
    }

    receive() external payable {
        //put emit here to track this
        this.deposit();
    }

    // function pause() public {
    //     _pause();
    // }

    // function unpause() public {
    //     _unpause();
    // }
}