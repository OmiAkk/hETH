// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "../src/interfaces/IWETH.sol";
import "../src/interfaces/IWETHEvents.sol";
import "./mock/DeployWETH9.sol";
import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-gas-snapshot/GasSnapshot.sol";

contract HuffWethGasTest is Test, GasSnapshot, IWETHEvents {
    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");
    address private charlie = makeAddr("charlie");

    IWETH public hETH;
    IWETH public wETH;

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

        /*
         * Deploy WETH9 for comparsion
         */
        wETH = IWETH(DeployWETH9.deploy());
        assertEq(wETH.symbol(), "WETH");

        // Deposit from Bob
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        wETH.deposit{value: 1 ether}();
        // Approve 1 wETH to Alice from Bob
        vm.prank(bob);
        wETH.approve(alice, 1 ether);

        // Deposit from Alice
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        wETH.deposit{value: 1 ether}(); // Alice has 1 wETH from the start

        // Snapshot contract size
        snapSize("wETH_contract_size", address(wETH));
    }

    ///////////////////////////////////////////////////
    //////////////// hETH Gas Snapshots ///////////////
    ///////////////////////////////////////////////////

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

    ///////////////////////////////////////////////////
    //////////////// WETH Gas Snapshots ///////////////
    ///////////////////////////////////////////////////

    function testName_weth() public {
        vm.startPrank(alice);
        snapStart("wETH.name()");

        wETH.name();

        snapEnd();
        vm.stopPrank();
    }

    function testSymbol_weth() public {
        vm.startPrank(alice);
        snapStart("wETH.symbol()");

        wETH.symbol();

        snapEnd();
        vm.stopPrank();
    }

    function testDecimals_weth() public {
        vm.startPrank(alice);
        snapStart("wETH.decimals()");

        wETH.decimals();

        snapEnd();
        vm.stopPrank();
    }

    function testFallbackWithExistingBalance_weth() public {
        vm.startPrank(alice);
        snapStart("wETH_callback_deposit_with_existing_balance");

        address(wETH).call{value: 1 ether}("");

        snapEnd();
        vm.stopPrank();
    }

    function testDepositWithExistingBalance_weth() public {
        vm.startPrank(alice);
        snapStart("wETH_deposit()_with_existing_balance");

        wETH.deposit{value: 1 ether}();

        snapEnd();
        vm.stopPrank();
    }

    function testPartialWithdraw_weth() public {
        // Withdraw 0.5 ETH
        vm.startPrank(alice);
        snapStart("wETH_partial_withdraw()");

        wETH.withdraw((1 ether) / 2);

        snapEnd();
        vm.stopPrank();
    }

    function testFullWithdraw_weth() public {
        // Withdraw 1 ETH
        vm.startPrank(alice);
        snapStart("wETH_full_withdraw()");

        wETH.withdraw(1 ether);

        snapEnd();
        vm.stopPrank();
        assertEq(wETH.balanceOf(alice), 0);
    }

    function testTotalSupply_weth() public {
        vm.startPrank(alice);
        snapStart("wETH.totalSupply()");

        wETH.totalSupply();

        snapEnd();
        vm.stopPrank();
    }

    function testFullTransferToAccountWithZeroBalance_weth() public {
        vm.startPrank(alice);
        snapStart("wETH.full_transfer_to_account_with_zero_balance()");

        wETH.transfer(charlie, 1 ether);

        snapEnd();
        vm.stopPrank();
        assertEq(wETH.balanceOf(alice), 0);
    }

    function testPartialTransferToAccountWithZeroBalance_weth() public {
        vm.startPrank(alice);
        snapStart("wETH.partial_transfer_to_account_with_zero_balance()");

        wETH.transfer(charlie, (1 ether) / 2);

        snapEnd();
        vm.stopPrank();
    }

    function testFullTransferToAccountWithNonZeroBalance_weth() public {
        assertGt(wETH.balanceOf(bob), 0);
        vm.startPrank(alice);
        snapStart("wETH.full_transfer_to_account_with_NON_zero_balance()");

        wETH.transfer(bob, 1 ether);

        snapEnd();
        vm.stopPrank();
        assertEq(wETH.balanceOf(alice), 0);
    }

    function testPartialTransferToAccountWithNonZeroBalance_weth() public {
        assertGt(wETH.balanceOf(bob), 0);
        vm.startPrank(alice);
        snapStart("wETH.partial_transfer_to_account_with_NON_zero_balance");

        wETH.transfer(bob, (1 ether) / 2);

        snapEnd();
        vm.stopPrank();
        assertGt(wETH.balanceOf(alice), 0);
    }

    function testFirstApprove_weth() public {
        // Give Bob max approval
        vm.startPrank(alice);
        snapStart("wETH.setting_nonzero_approval_from_zero");

        wETH.approve(bob, type(uint256).max);

        snapEnd();
        vm.stopPrank();
    }

    function testChangeApprove_weth() public {
        vm.startPrank(alice);

        wETH.approve(bob, 100);

        // Give Bob max approval
        snapStart("wETH.changing_nonzero_approval_to_nonzero");

        wETH.approve(bob, type(uint256).max);

        snapEnd();
        vm.stopPrank();
    }

    function testRevokeApprove_weth() public {
        vm.startPrank(alice);

        wETH.approve(bob, 100);

        // Revoke approval
        snapStart("wETH.changing_nonzero_approval_to_zero");

        wETH.approve(bob, 0);

        snapEnd();
        vm.stopPrank();
    }

    function testPartialTransferFrom_weth() public {
        // Transfer 0.5 wETH
        vm.startPrank(alice);
        snapStart("wETH.partial_transferFrom_to_account_with_zero_balance");

        wETH.transferFrom(bob, charlie, (1 ether) / 2);

        snapEnd();
        vm.stopPrank();

        assertGt(wETH.balanceOf(bob), 0);
    }

    function testFullTransferFrom_weth() public {
        vm.startPrank(alice);
        snapStart("wETH.full_transferFrom_to_account_with_zero_balance");

        wETH.transferFrom(bob, charlie, 1 ether);

        snapEnd();
        vm.stopPrank();

        assertEq(wETH.balanceOf(bob), 0);
    }
}
