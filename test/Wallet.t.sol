// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Wallet.sol";
import {MockERC20} from "./MockERC20.sol";

contract MirageWalletTest is Test {
    MirageWallet wallet;
    MockERC20 mockToken1;
    MockERC20 mockToken2;

    address owner = address(1);
    address user = address(2);
    address recipient = address(3);

    function setUp() public {
        vm.startPrank(owner);
        wallet = new MirageWallet();
        mockToken1 = new MockERC20("Mock Token 1", "MTK1");
        mockToken2 = new MockERC20("Mock Token 2", "MTK2");

        // Mint tokens to the wallet
        mockToken1.mint(address(wallet), 1000 ether);
        mockToken2.mint(address(wallet), 500 ether);
        vm.stopPrank();
    }

    function testDeployment() public view {
        assertEq(wallet.owner(), owner);
        assertEq(wallet.paused(), false);
    }

    function testReceiveEther() public {
        uint256 initialBalance = address(wallet).balance;

        vm.deal(user, 1 ether);
        vm.prank(user);
        (bool success,) = address(wallet).call{value: 0.5 ether}("");

        assertTrue(success);
        assertEq(address(wallet).balance, initialBalance + 0.5 ether);
    }

    function testWithdraw() public {
        // Fund the wallet
        vm.deal(address(wallet), 1 ether);

        uint256 initialWalletBalance = address(wallet).balance;
        uint256 initialRecipientBalance = address(recipient).balance;

        // Withdraw as owner
        vm.prank(owner);
        wallet.withdraw(0.5 ether, payable(recipient));

        assertEq(address(wallet).balance, initialWalletBalance - 0.5 ether);
        assertEq(address(recipient).balance, initialRecipientBalance + 0.5 ether);
    }

    function testWithdrawUnauthorized() public {
        vm.deal(address(wallet), 1 ether);

        // Try to withdraw as non-owner
        vm.prank(user);
        vm.expectRevert();
        wallet.withdraw(0.5 ether, payable(recipient));
    }

    function testAddSupportedTokens() public {
        address[] memory tokens = new address[](2);
        tokens[0] = address(mockToken1);
        tokens[1] = address(mockToken2);

        vm.prank(owner);
        wallet.addSupportedTokens(tokens);

        assertTrue(wallet.supportedTokens(address(mockToken1)));
        assertTrue(wallet.supportedTokens(address(mockToken2)));

        address[] memory supportedTokens = wallet.getSupportedTokens();
        assertEq(supportedTokens.length, 2);
        assertEq(supportedTokens[0], address(mockToken1));
        assertEq(supportedTokens[1], address(mockToken2));
    }

    function testRemoveSupportedToken() public {
        // First add tokens
        address[] memory tokens = new address[](2);
        tokens[0] = address(mockToken1);
        tokens[1] = address(mockToken2);

        vm.startPrank(owner);
        wallet.addSupportedTokens(tokens);

        // Now remove one token
        wallet.removeSupportedToken(address(mockToken1));
        vm.stopPrank();

        assertFalse(wallet.supportedTokens(address(mockToken1)));
        assertTrue(wallet.supportedTokens(address(mockToken2)));

        address[] memory supportedTokens = wallet.getSupportedTokens();
        assertEq(supportedTokens.length, 1);
        assertEq(supportedTokens[0], address(mockToken2));
    }

    function testWithdrawToken() public {
        uint256 initialTokenBalance = mockToken1.balanceOf(address(wallet));

        vm.prank(owner);
        wallet.withdrawToken(address(mockToken1), 100 ether, recipient);

        assertEq(mockToken1.balanceOf(address(wallet)), initialTokenBalance - 100 ether);
        assertEq(mockToken1.balanceOf(recipient), 100 ether);
    }

    function testBatchWithdrawTokens() public {
        uint256 initialToken1Balance = mockToken1.balanceOf(address(wallet));
        uint256 initialToken2Balance = mockToken2.balanceOf(address(wallet));

        address[] memory tokens = new address[](2);
        tokens[0] = address(mockToken1);
        tokens[1] = address(mockToken2);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 50 ether;
        amounts[1] = 25 ether;

        vm.prank(owner);
        wallet.batchWithdrawTokens(tokens, amounts, recipient);

        assertEq(mockToken1.balanceOf(address(wallet)), initialToken1Balance - 50 ether);
        assertEq(mockToken2.balanceOf(address(wallet)), initialToken2Balance - 25 ether);
        assertEq(mockToken1.balanceOf(recipient), 50 ether);
        assertEq(mockToken2.balanceOf(recipient), 25 ether);
    }

    function testGetAllTokenBalances() public {
        // First add tokens
        address[] memory tokens = new address[](2);
        tokens[0] = address(mockToken1);
        tokens[1] = address(mockToken2);

        vm.prank(owner);
        wallet.addSupportedTokens(tokens);

        // Get balances
        (address[] memory returnedTokens, uint256[] memory balances) = wallet.getAllTokenBalances();

        assertEq(returnedTokens.length, 2);
        assertEq(balances.length, 2);
        assertEq(returnedTokens[0], address(mockToken1));
        assertEq(returnedTokens[1], address(mockToken2));
        assertEq(balances[0], 1000 ether);
        assertEq(balances[1], 500 ether);
    }

    function testPause() public {
        vm.deal(address(wallet), 1 ether);

        // Pause the contract
        vm.prank(owner);
        wallet.setPaused(true);
        assertTrue(wallet.paused());

        // Try to withdraw while paused
        vm.prank(owner);
        vm.expectRevert("Contract is paused");
        wallet.withdraw(0.5 ether, payable(recipient));

        // Try to withdraw token while paused
        vm.prank(owner);
        vm.expectRevert("Contract is paused");
        wallet.withdrawToken(address(mockToken1), 100 ether, recipient);

        // Unpause
        vm.prank(owner);
        wallet.setPaused(false);
        assertFalse(wallet.paused());

        // Should be able to withdraw now
        vm.prank(owner);
        wallet.withdraw(0.5 ether, payable(recipient));
    }

    function testRecoverERC20() public {
        uint256 initialTokenBalance = mockToken1.balanceOf(address(wallet));

        vm.prank(owner);
        wallet.recoverERC20(address(mockToken1));

        assertEq(mockToken1.balanceOf(address(wallet)), 0);
        assertEq(mockToken1.balanceOf(owner), initialTokenBalance);
    }

    function testFailRecoverERC20NoTokens() public {
        // Create a new token with no balance in the wallet
        MockERC20 emptyToken = new MockERC20("Empty Token", "EMPTY");

        vm.prank(owner);
        wallet.recoverERC20(address(emptyToken));
        // This should revert with "No tokens to recover"
    }

    function testFailAddInvalidToken() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(0); // Invalid zero address

        vm.prank(owner);
        wallet.addSupportedTokens(tokens);
        // This should revert with "Invalid token address"
    }

    function testFailRemoveUnsupportedToken() public {
        vm.prank(owner);
        wallet.removeSupportedToken(address(mockToken1));
        // This should revert with "Token not supported"
    }

    function testFailBatchWithdrawMismatchedArrays() public {
        address[] memory tokens = new address[](2);
        tokens[0] = address(mockToken1);
        tokens[1] = address(mockToken2);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 50 ether;

        vm.prank(owner);
        wallet.batchWithdrawTokens(tokens, amounts, recipient);
        // This should revert with "Arrays length mismatch"
    }

    function testFailWithdrawInsufficientFunds() public {
        vm.deal(address(wallet), 0.5 ether);

        vm.prank(owner);
        wallet.withdraw(1 ether, payable(recipient));
        // This should revert with "Insufficient funds"
    }

    function testFailWithdrawTokenInsufficientBalance() public {
        vm.prank(owner);
        wallet.withdrawToken(address(mockToken1), 2000 ether, recipient);
        // This should revert with "Insufficient token balance"
    }

    function testFailWithdrawToZeroAddress() public {
        vm.deal(address(wallet), 1 ether);

        vm.prank(owner);
        wallet.withdraw(0.5 ether, payable(address(0)));
        // This should revert with "Invalid recipient"
    }

    function testFailWithdrawTokenToZeroAddress() public {
        vm.prank(owner);
        wallet.withdrawToken(address(mockToken1), 100 ether, address(0));
        // This should revert with "Invalid recipient"
    }
}
