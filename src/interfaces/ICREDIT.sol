// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICREDIT {
    function createCREDIT(address customer, uint256 amount) external;

    function subtractValueFromCREDIT(
        address customer,
        uint256 tokenId,
        uint256 amount
    ) external;

    function deleteCREDIT(address customer, uint256 tokenId)
        external
        returns (uint256 value);

    function transferFrom(
        address customer,
        address to,
        uint256 tokenId
    ) external;

    function balanceOfCredit(uint256 tokenId) external view returns (uint256);

    function timeOfCredit(uint256 tokenId) external view returns (uint256);

    function transferOwnership(address newOwner) external;
}
