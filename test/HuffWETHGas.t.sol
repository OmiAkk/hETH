// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "../src/interfaces/IWETH.sol";
import "../src/interfaces/IWETHEvents.sol";
import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-gas-snapshot/GasSnapshot.sol";

contract HuffWethGasTest is Test, GasSnapshot, IWETHEvents {
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
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        hETH.deposit{value: 1 ether}(); // Alice has 1 hETH from the start

        // Snapshot contract size
        snapSize("hETH_contract_size", address(hETH));
    }

    function testName() public {
        vm.startPrank(alice);
        snapStart("hETH.name()");

        hETH.name();

        snapEnd();
        vm.stopPrank();
    }

    function testSymbol() public {
        vm.startPrank(alice);
        snapStart("hETH.symbol()");

        hETH.symbol();

        snapEnd();
        vm.stopPrank();
    }

    function testDecimals() public {
        vm.startPrank(alice);
        snapStart("hETH.decimals()");

        hETH.decimals();

        snapEnd();
        vm.stopPrank();
    }

    function testFallbackWithExistingBalance() public {
        vm.startPrank(alice);
        snapStart("hETH_callback_deposit_with_existing_balance");

        address(hETH).call{value: 1 ether}("");

        snapEnd();
        vm.stopPrank();
    }

    function testDepositWithExistingBalance() public {
        vm.startPrank(alice);
        snapStart("hETH_deposit()_with_existing_balance");

        hETH.deposit{value: 1 ether}();

        snapEnd();
        vm.stopPrank();
    }

    function testPartialWithdraw() public {
        // Withdraw 0.5 ETH
        vm.startPrank(alice);
        snapStart("hETH_partial_withdraw()");

        hETH.withdraw((1 ether) / 2);

        snapEnd();
        vm.stopPrank();
    }

    function testFullWithdraw() public {
        // Withdraw 1 ETH
        vm.startPrank(alice);
        snapStart("hETH_full_withdraw()");

        hETH.withdraw(1 ether);

        snapEnd();
        vm.stopPrank();
        assertEq(hETH.balanceOf(alice), 0);
    }

    function testTotalSupply() public {
        vm.startPrank(alice);
        snapStart("hETH.totalSupply()");

        hETH.totalSupply();

        snapEnd();
        vm.stopPrank();
    }

    function testFullTransferToAccountWithZeroBalance() public {
        vm.startPrank(alice);
        snapStart("hETH.full_transfer_to_account_with_zero_balance()");

        hETH.transfer(charlie, 1 ether);

        snapEnd();
        vm.stopPrank();
        assertEq(hETH.balanceOf(alice), 0);
    }

    function testPartialTransferToAccountWithZeroBalance() public {
        vm.startPrank(alice);
        snapStart("hETH.partial_transfer_to_account_with_zero_balance()");

        hETH.transfer(charlie, (1 ether) / 2);

        snapEnd();
        vm.stopPrank();
    }

    function testFullTransferToAccountWithNonZeroBalance() public {
        assertGt(hETH.balanceOf(bob), 0);
        vm.startPrank(alice);
        snapStart("hETH.full_transfer_to_account_with_NON_zero_balance()");

        hETH.transfer(bob, 1 ether);

        snapEnd();
        vm.stopPrank();
        assertEq(hETH.balanceOf(alice), 0);
    }

    function testPartialTransferToAccountWithNonZeroBalance() public {
        assertGt(hETH.balanceOf(bob), 0);
        vm.startPrank(alice);
        snapStart("hETH.partial_transfer_to_account_with_NON_zero_balance");

        hETH.transfer(bob, (1 ether) / 2);

        snapEnd();
        vm.stopPrank();
        assertGt(hETH.balanceOf(alice), 0);
    }

    function testFirstApprove() public {
        // Give Bob max approval
        vm.startPrank(alice);
        snapStart("hETH.setting_nonzero_approval_from_zero");

        hETH.approve(bob, type(uint256).max);

        snapEnd();
        vm.stopPrank();
    }

    function testChangeApprove() public {
        vm.startPrank(alice);

        hETH.approve(bob, 100);

        // Give Bob max approval
        snapStart("hETH.changing_nonzero_approval_to_nonzero");

        hETH.approve(bob, type(uint256).max);

        snapEnd();
        vm.stopPrank();
    }

    function testRevokeApprove() public {
        vm.startPrank(alice);

        hETH.approve(bob, 100);

        // Revoke approval
        snapStart("hETH.changing_nonzero_approval_to_zero");

        hETH.approve(bob, 0);

        snapEnd();
        vm.stopPrank();
    }

    function testPartialTransferFrom() public {
        // Transfer 0.5 hETH
        vm.startPrank(alice);
        snapStart("hETH.partial_transferFrom_to_account_with_zero_balance");

        hETH.transferFrom(bob, charlie, (1 ether) / 2);

        snapEnd();
        vm.stopPrank();

        assertGt(hETH.balanceOf(bob), 0);
    }

    function testFullTransferFrom() public {
        vm.startPrank(alice);
        snapStart("hETH.full_transferFrom_to_account_with_zero_balance");

        hETH.transferFrom(bob, charlie, 1 ether);

        snapEnd();
        vm.stopPrank();

        assertEq(hETH.balanceOf(bob), 0);
    }
}
