// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITOKENMANAGER {
    function deposit(uint256 amount) external returns (uint256);

    function claimUnderlying(uint256 tokenId) external returns (uint256);

    function decreaseCredit(uint256 tokenId, uint256 amount)
        external
        returns (uint256);
}