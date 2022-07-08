// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICREDIT {
    function createCREDIT(address customer, uint256 amount) external;

    function addValueToCREDIT(
        address customer,
        uint256 tokenId,
        uint256 amount
    ) external;

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

    function transferOwnership(address newOwner) external;
}
