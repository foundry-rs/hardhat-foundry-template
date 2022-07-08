// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ICREDS.sol";
import "../interfaces/ICREDIT.sol";

error CeilingReached();
error EmptySend();
error EmergencyNotActive();
error EmergencyActive();
error NoFeesToTransfer();
error FeeTooLow();
error FeeTooHigh();

contract TokenManagerETH is Ownable, Pausable, ReentrancyGuard {
    ICREDS public creds;
    ICREDIT public credit;

    uint256 public globalDepositValue;
    uint256 public globalCeiling;
    uint256 public feePercentage = 5; //0.5%; use basis points instead
    uint256 public feeToTransfer;

    uint256 public emergencyStatus = 1; //inactive by default
    uint256 private immutable emergencyNotActive = 1;
    uint256 private immutable emergencyActive = 2;

    address payable public treasury;

    uint256 private constant MINIMUM_FEE_PERCENTAGE = 1;
    uint256 private constant MAXIMUM_FEE_PERCENTAGE = 10;

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
        address payable _treasury,
        uint256 _globalCeiling
    ) {
        creds = _creds;
        credit = _credit;
        treasury = _treasury;
        globalCeiling = _globalCeiling;
    }

    function deposit() public payable whenNotPaused nonReentrant {
        if (msg.value == 0) revert EmptySend();
        if (globalDepositValue >= globalCeiling) revert CeilingReached();

        address customer = msg.sender;
        uint256 adjustedFee = _calculateFee(msg.value);
        feeToTransfer += adjustedFee;
        uint256 amount = msg.value - adjustedFee;
        globalDepositValue += amount;
        creds.mint(customer, amount);
        credit.createCREDIT(customer, amount);
        emit Deposit(customer, amount);
    }

    //create an add function here

    function partialWithdraw(uint256 tokenId, uint256 amount)
        public
        whenNotPaused
        nonReentrant
    {
        address customer = msg.sender;
        creds.burn(customer, amount);
        credit.subtractValueFromCREDIT(customer, tokenId, amount);
        globalDepositValue -= amount;
        (bool success, ) = payable(customer).call{value: amount}("");
        require(success, "Partial withdraw failed");
        emit SubtractFromCredit(customer, tokenId, amount);
    }

    function claimAllUnderlying(uint256 tokenId)
        public
        whenNotPaused
        nonReentrant
    {
        address customer = msg.sender;
        uint256 amount = credit.deleteCREDIT(customer, tokenId); //use other method for this
        globalDepositValue -= amount;
        creds.burn(customer, amount);
        (bool success, ) = payable(customer).call{value: amount}("");
        require(success, "Total Claim failed");
        emit Withdrawal(customer, amount);
    }

    receive() external payable {
        //put emit here to track this
        deposit();
    }

    function activateEmergency() public onlyOwner whenPaused {
        if (emergencyStatus == emergencyActive) revert EmergencyActive();
        emergencyStatus = emergencyActive;
    }

    function deactivateEmergency() public onlyOwner {
        if (emergencyStatus == emergencyNotActive) revert EmergencyNotActive();
        emergencyStatus = emergencyNotActive;
    }

    //same as claimAllUnderlying except customer doesnt need an equal number of creds
    function emergencyWithdraw(uint256 tokenId) public whenPaused nonReentrant {
        if (emergencyStatus == emergencyNotActive) revert EmergencyNotActive();

        address customer = msg.sender;
        uint256 amount = credit.deleteCREDIT(customer, tokenId);
        globalDepositValue -= amount;
        (bool success, ) = payable(customer).call{value: amount}("");
        require(success, "Emergency Withdraw Failed");
        emit Withdrawal(customer, amount);
    }

    //change this to use basis points instead
    function _calculateFee(uint256 msgValue) internal view returns (uint256) {
        uint256 adjustedMsgValue;
        if (feePercentage == 1) {
            adjustedMsgValue = msgValue / 100;
            return adjustedMsgValue;
        }
        adjustedMsgValue = (msgValue * feePercentage) / 100;
        return adjustedMsgValue;
    }

    function setTreasuryAddress(address payable _newTreasuryAddress)
        public
        onlyOwner
    {
        treasury = _newTreasuryAddress;
    }

    function sendToFeesTreasury() public onlyOwner {
        if (feeToTransfer == 0) revert NoFeesToTransfer();

        uint256 allFees = feeToTransfer;
        feeToTransfer -= allFees;
        (bool success, ) = treasury.call{value: allFees}("");
        require(success, "fee send failed");
    }

    function setFeePercentage(uint256 _feePercentage) public onlyOwner {
        if (_feePercentage < MINIMUM_FEE_PERCENTAGE) revert FeeTooLow();

        if (_feePercentage > MAXIMUM_FEE_PERCENTAGE) revert FeeTooHigh();

        feePercentage = _feePercentage;
    }

    function adjustCeiling(uint256 _amount) public onlyOwner {
        globalCeiling = _amount;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        if (emergencyStatus == emergencyActive) revert EmergencyActive();
        _unpause();
    }
}
