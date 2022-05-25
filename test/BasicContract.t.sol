// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/BasicContract.sol";

contract BasicContractTest is Test {
    BasicContract c;

    function setUp() public {
        c = new BasicContract();
    }

    function testExample() public {
        assertTrue(c.returnsTrue());
    }
}
