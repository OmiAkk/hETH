// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "../src/interfaces/IWETH.sol";
import "../src/interfaces/IWETHEvents.sol";
import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract HuffWethTest is Test, IWETHEvents {
    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");
    address private charlie = makeAddr("charlie");
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

    function testFallback() public {
        assertEq(hETH.totalSupply(), 0);
        assertEq(address(hETH).balance, 0);
        assertEq(hETH.balanceOf(address(this)), 0);

        vm.deal(address(this), 1 ether);
        vm.expectEmit(address(hETH));
        emit Deposit(address(this), 1 ether);
        (bool success, ) = address(hETH).call{value: 1 ether}("");
        require(success, "Fallback failed");

        assertEq(hETH.totalSupply(), 1 ether);
        assertEq(address(hETH).balance, 1 ether);
        assertEq(hETH.balanceOf(address(this)), 1 ether);
    }

    function testDeposit() public {
        assertEq(hETH.totalSupply(), 0);
        assertEq(address(hETH).balance, 0);
        assertEq(hETH.balanceOf(address(this)), 0);

        vm.deal(address(this), 1 ether);
        vm.expectEmit(address(hETH));
        emit Deposit(address(this), 1 ether);
        hETH.deposit{value: 1 ether}();

        assertEq(hETH.totalSupply(), 1 ether);
        assertEq(address(hETH).balance, 1 ether);
        assertEq(hETH.balanceOf(address(this)), 1 ether);
    }

    function testWithdrawAfterDeposit() public {
        vm.startPrank(alice);
        // Deposit 1 ETH
        assertEq(hETH.totalSupply(), 0);
        assertEq(address(hETH).balance, 0);
        assertEq(hETH.balanceOf(alice), 0);
        assertEq(alice.balance, 0);

        vm.deal(alice, 1 ether);
        hETH.deposit{value: 1 ether}();

        assertEq(hETH.totalSupply(), 1 ether);
        assertEq(address(hETH).balance, 1 ether);
        assertEq(hETH.balanceOf(alice), 1 ether);
        assertEq(alice.balance, 0);

        // Withdraw 0.5 ETH
        vm.expectEmit(address(hETH));
        emit Withdrawal(alice, (1 ether) / 2);
        hETH.withdraw((1 ether) / 2);

        assertEq(hETH.totalSupply(), (1 ether) / 2);
        assertEq(address(hETH).balance, (1 ether) / 2);
        assertEq(hETH.balanceOf(alice), (1 ether) / 2);
        assertEq(alice.balance, (1 ether) / 2);
        vm.stopPrank();

        // Test unsuccessful withdrawal
        vm.prank(bob);
        vm.expectRevert();
        hETH.withdraw((1 ether) / 4);

        // Bob can't withdraw more than he has
        vm.deal(bob, (1 ether / 2)); // 0.5 ETH
        vm.startPrank(bob);

        hETH.deposit{value: (1 ether / 2)}();
        vm.expectRevert();
        hETH.withdraw((3 ether) / 5); // Bob can't withdraw 0.6 ETH

        // Bob can withdraw what he deposited
        vm.expectEmit(address(hETH));
        emit Withdrawal(bob, (1 ether) / 2);
        hETH.withdraw((1 ether) / 2);

        vm.stopPrank();
    }

    function testWithdrawAfterFallbackDeposit() public {
        vm.startPrank(alice);

        assertEq(hETH.totalSupply(), 0);
        assertEq(address(hETH).balance, 0);
        assertEq(hETH.balanceOf(alice), 0);
        assertEq(alice.balance, 0);

        // Deposit 1 ETH
        vm.deal(alice, 1 ether);
        (bool success, ) = address(hETH).call{value: 1 ether}("");
        require(success, "Fallback failed");

        assertEq(hETH.totalSupply(), 1 ether);
        assertEq(address(hETH).balance, 1 ether);
        assertEq(hETH.balanceOf(alice), 1 ether);
        assertEq(alice.balance, 0);

        // Withdraw 0.5 ETH
        vm.expectEmit(address(hETH));
        emit Withdrawal(alice, (1 ether) / 2);
        hETH.withdraw((1 ether) / 2);

        assertEq(hETH.totalSupply(), (1 ether) / 2);
        assertEq(address(hETH).balance, (1 ether) / 2);
        assertEq(hETH.balanceOf(alice), (1 ether) / 2);
        assertEq(alice.balance, (1 ether) / 2);
        vm.stopPrank();
    }

    function testTotalSupply() public {
        vm.deal(alice, 11 ether);
        vm.startPrank(alice);

        assertEq(hETH.totalSupply(), 0);

        // Deposit 1 ether via deposit()
        hETH.deposit{value: 1 ether}();
        assertEq(hETH.totalSupply(), 1 ether);

        // Deposit 10 ether via fallback()
        (bool success, ) = address(hETH).call{value: 10 ether}("");
        require(success, "Fallback failed");
        assertEq(hETH.totalSupply(), 11 ether);

        // Withdraw 5 ETH
        hETH.withdraw(5 ether);
        assertEq(hETH.totalSupply(), 6 ether);

        vm.stopPrank();
    }

    function testTransfer() public {
        vm.deal(alice, 1 ether);
        vm.startPrank(alice);

        // Deposit 1 ether via deposit()
        hETH.deposit{value: 1 ether}();
        assertEq(hETH.balanceOf(alice), 1 ether);
        assertEq(hETH.balanceOf(bob), 0);

        // Transfer 0.1 hETH to bob
        vm.expectEmit(address(hETH));
        emit Transfer(alice, bob, (1 ether) / 10);
        hETH.transfer(bob, (1 ether) / 10);

        assertEq(hETH.balanceOf(alice), ((1 ether) / 10) * 9); // Alice's balance should be equal 0.9 hETH
        assertEq(hETH.balanceOf(bob), (1 ether) / 10); // Bob's balance should be equal 0.1 hETH
        assertEq(hETH.totalSupply(), 1 ether);

        vm.stopPrank();
    }

    function testTransferRevert() public {
        vm.deal(alice, 1 ether);
        vm.startPrank(alice);

        // Deposit 1 ether via deposit()
        hETH.deposit{value: 1 ether}();
        // Alice should not be able to transfer more than she has
        vm.expectRevert();
        hETH.transfer(bob, 100 ether); // 100 hETH

        vm.stopPrank();
    }

    function testApprove() public {
        vm.deal(alice, 1 ether);
        vm.startPrank(alice);

        // Deposit 1 ether via deposit()
        hETH.deposit{value: 1 ether}();
        assertEq(hETH.balanceOf(alice), 1 ether);
        assertEq(hETH.balanceOf(bob), 0);
        assertEq(hETH.allowance(alice, bob), 0);

        // Approve 0.1 hETH to bob
        vm.expectEmit(address(hETH));
        emit Approval(alice, bob, (1 ether) / 10);
        hETH.approve(bob, (1 ether) / 10);
        assertEq(hETH.balanceOf(alice), 1 ether); // Alice's balance should be equal 1 hETH
        assertEq(hETH.balanceOf(bob), 0); // Bob's balance should be equal 0 hETH
        assertEq(hETH.totalSupply(), 1 ether);
        assertEq(hETH.allowance(alice, bob), (1 ether) / 10);

        // Remove allowance of hETH to bob
        vm.expectEmit(address(hETH));
        emit Approval(alice, bob, 0);
        hETH.approve(bob, 0);
        assertEq(hETH.balanceOf(alice), 1 ether); // Alice's balance should be equal 1 hETH
        assertEq(hETH.balanceOf(bob), 0); // Bob's balance should be equal 0 hETH
        assertEq(hETH.totalSupply(), 1 ether);
        assertEq(hETH.allowance(alice, bob), 0);

        // Set max allowance
        vm.expectEmit(address(hETH));
        emit Approval(alice, bob, type(uint256).max);
        hETH.approve(bob, type(uint256).max);
        assertEq(hETH.balanceOf(alice), 1 ether); // Alice's balance should be equal 1 hETH
        assertEq(hETH.balanceOf(bob), 0); // Bob's balance should be equal 0 hETH
        assertEq(hETH.totalSupply(), 1 ether);
        assertEq(hETH.allowance(alice, bob), type(uint256).max);

        vm.stopPrank();
    }

    function testTransferFrom() public {
        vm.deal(alice, 10 ether);
        vm.startPrank(alice);

        // Deposit 10 ether via deposit()
        hETH.deposit{value: 10 ether}();

        // Approve 1 hETH to Bob
        hETH.approve(bob, 1 ether);
        vm.stopPrank();

        vm.startPrank(bob);

        // Transfer 0.25 hETH from Alice to Charlie
        vm.expectEmit(address(hETH));
        emit Transfer(alice, charlie, (1 ether) / 4);
        hETH.transferFrom(alice, charlie, (1 ether) / 4);

        assertEq(hETH.balanceOf(alice), 9 ether + (3 ether) / 4); // 9.75 hETH
        assertEq(hETH.balanceOf(bob), 0);
        assertEq(hETH.balanceOf(charlie), (1 ether) / 4); // 0.25 hETH
        assertEq(hETH.totalSupply(), 10 ether);
        assertEq(hETH.allowance(alice, bob), (3 ether) / 4); // 0.75 hETH

        // Transfer 0.5 hETH from Alice to Bob
        vm.expectEmit(address(hETH));
        emit Transfer(alice, bob, (1 ether) / 2);
        hETH.transferFrom(alice, bob, (1 ether) / 2);

        assertEq(hETH.balanceOf(alice), 9 ether + (1 ether) / 4); // 9.25 hETH
        assertEq(hETH.balanceOf(bob), (1 ether) / 2); // 0.5 hETH
        assertEq(hETH.balanceOf(charlie), (1 ether) / 4); // 0.25 hETH
        assertEq(hETH.totalSupply(), 10 ether);
        assertEq(hETH.allowance(alice, bob), (1 ether) / 4); // 0.25 hETH

        // Revert if Bob tries to transferFrom Alice more than allowed
        vm.expectRevert();
        hETH.transferFrom(alice, bob, 5 ether);

        vm.stopPrank();

        // Bob can take 5 hETH from Alice if she set max approval
        vm.prank(alice);
        hETH.approve(bob, type(uint256).max);

        vm.startPrank(bob);

        vm.expectEmit(address(hETH));
        emit Transfer(alice, bob, 5 ether);
        hETH.transferFrom(alice, bob, 5 ether);
        assertEq(hETH.balanceOf(alice), 4 ether + (1 ether) / 4); // 4.25 hETH
        assertEq(hETH.balanceOf(bob), 5 ether + (1 ether) / 2); // 0.5 hETH
        assertEq(hETH.balanceOf(charlie), (1 ether) / 4); // 0.25 hETH
        assertEq(hETH.totalSupply(), 10 ether);
        assertEq(hETH.allowance(alice, bob), type(uint256).max); // Max allowance

        vm.stopPrank();
    }
}
