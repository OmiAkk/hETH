// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "../src/interfaces/IWETH.sol";
import "../src/interfaces/IWETHEvents.sol";
import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract HuffWethGasTest is Test, IWETHEvents {
    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");
    address private charlie = makeAddr("charlie");
    IWETH public hETH;

    function setUp() public {
        // Deploy hETH contract
        hETH = IWETH(HuffDeployer.deploy("HuffWETH"));

        // Deposit from Bob
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        hETH.deposit{value: 1 ether}();
        // Approve 1 hETH to Alice from Bob
        vm.prank(bob);
        hETH.approve(alice, 1 ether);

        // Deposit from Alice
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        hETH.deposit{value: 1 ether}(); // Alice has 1 hETH from the start
    }

    function testName() public {
        hETH.name();
    }

    function testSymbol() public {
        hETH.symbol();
    }

    function testDecimals() public {
        hETH.decimals();
    }

    function testFallbackWithExistingBalance() public {
        address(hETH).call{value: 1 ether}("");
    }

    function testDepositWithExistingBalance() public {
        hETH.deposit{value: 1 ether}();
    }

    function testPartialWithdraw() public {
        // Withdraw 0.5 ETH
        vm.prank(alice);
        hETH.withdraw((1 ether) / 2);
    }

    function testFullWithdraw() public {
        // Withdraw 1 ETH
        vm.prank(alice);
        hETH.withdraw(1 ether);
    }

    function testTotalSupply() public {
        hETH.totalSupply();
    }

    function testFullTransferToAccountWithZeroBalance() public {
        vm.prank(alice);
        hETH.transfer(charlie, 1 ether);
    }

    function testPartialTransferToAccountWithZeroBalance() public {
        vm.prank(alice);
        hETH.transfer(charlie, (1 ether) / 2);
    }

    function testFullTransferToAccountWithNonZeroBalance() public {
        vm.prank(alice);
        hETH.transfer(bob, 1 ether);
    }

    function testPartialTransferToAccountWithNonZeroBalance() public {
        vm.prank(alice);
        hETH.transfer(bob, (1 ether) / 2);
    }

    function testApprove() public {
        // Give Bob max approval
        vm.prank(alice);
        hETH.approve(bob, type(uint256).max);
    }

    function testPartialTransferFrom() public {
        // 0.5 ETH
        vm.prank(alice);
        hETH.transferFrom(bob, charlie, (1 ether) / 2);
    }

    function testFullTransferFrom() public {
        vm.prank(alice);
        hETH.transferFrom(bob, charlie, 1 ether);
    }
}
