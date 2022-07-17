// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol"; //use oz instead

import "../interfaces/ICREDS.sol";
import "../interfaces/ICREDIT.sol";

contract TokenManager is ReentrancyGuard {
    using SafeTransferLib for ERC20;

    error EmptySend();
    error WrongSend();

    ICREDS private creds;
    ICREDIT private credit;

    uint256 public globalDepositValue;
    address public tokenAddress;

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);
    event SubtractFromCredit(
        address indexed customer,
        uint256 tokenId,
        uint256 amount
    );

    constructor(
        ICREDS _creds,
        ICREDIT _credit,
        address _tokenAddress
    ) {
        creds = _creds;
        credit = _credit;
        tokenAddress = _tokenAddress;
    }

    function deposit(uint256 amount) external nonReentrant returns (uint256) {
        if (amount == 0) revert EmptySend();

        address customer = msg.sender;
        uint256 priorBalance = ERC20(tokenAddress).balanceOf(address(this));
        ERC20(tokenAddress).safeTransferFrom(customer, address(this), amount);
        uint256 afterBalance = ERC20(tokenAddress).balanceOf(address(this));
        if (afterBalance < priorBalance) revert WrongSend(); //fix error message
        uint256 amountReceived = afterBalance - priorBalance;
        globalDepositValue += amountReceived;
        creds.mint(customer, amountReceived);
        credit.createCREDIT(customer, amountReceived);
        emit Deposit(customer, amountReceived);
        return creds.balanceOfCreds(customer);
    }

    //consolidate this and the claimUnderlying function
    //call new function which determines which private function to call
    function decreaseCredit(uint256 tokenId, uint256 amount)
        external
        nonReentrant
        returns (uint256)
    {
        address customer = msg.sender;
        globalDepositValue -= amount;
        credit.subtractValueFromCREDIT(customer, tokenId, amount);
        creds.burn(customer, amount);
        ERC20(tokenAddress).safeTransferFrom(address(this), customer, amount);
        emit SubtractFromCredit(customer, tokenId, amount);
        return creds.balanceOfCreds(customer);
    }

    function claimUnderlying(uint256 tokenId)
        external
        nonReentrant
        returns (uint256)
    {
        address customer = msg.sender;
        uint256 amount = credit.deleteCREDIT(customer, tokenId);
        globalDepositValue -= amount;
        creds.burn(customer, amount);
        ERC20(tokenAddress).safeTransferFrom(address(this), customer, amount);
        emit Withdrawal(customer, amount);
        return amount;
    }

    function getTotalBalance() external view returns (uint256) {
        return globalDepositValue;
    }
}
