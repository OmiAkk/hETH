// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "../src/interfaces/IWETH.sol";
import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract HuffWethTest is Test {
    IWETH public hETH;

    function setUp() public {
        hETH = IWETH(HuffDeployer.deploy("HuffWETH"));
    }

    function testName() public {
        assertEq("Huff Wrapped ETH", hETH.name());
    }

    function testSymbol() public {
        assertEq("HETH", hETH.symbol());
    }

    function testDecimals() public {
        assertEq(18, hETH.decimals());
    }
}
