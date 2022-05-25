// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/Contract.sol";

contract ContractTest is Test {
    Contract c;

    function setUp() public {
        c = new Contract();
    }

    function testExample() public {
        assertTrue(c.returnsTrue());
    }
}
