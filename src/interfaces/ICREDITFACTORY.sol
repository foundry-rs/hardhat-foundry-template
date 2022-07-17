// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICREDITFACTORY {
    function registerCredit(address tokenAddress)
        external
        returns (
            address,
            address,
            address
        );

    function getCreditMapping(address tokenAddress)
        external
        view
        returns (
            address,
            address,
            address
        );

    function getAllRegisteredAddresses(address[] memory poolAddresses)
        external
        view
        returns (address[] memory);
}