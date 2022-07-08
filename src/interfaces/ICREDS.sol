// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICREDS {
    function mint(address to, uint256 amount) external;

    function burn(address customer, uint256 amount) external;

    function transferFrom(
        address customer,
        address to,
        uint256 amount
    ) external;

    function balanceOfCreds(address customer) external view returns (uint256);

    function transferOwnership(address newOwner) external;
}
