// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {EnhancedWallet} from "../src/Wallet.sol";

contract DeployWallet is Script {
    function run() external returns (EnhancedWallet) {
        // Default daily limit (1 ETH)
        uint256 dailyLimit = 1 ether;
        
        // Get daily limit from environment if provided
        if (vm.envOr("DAILY_LIMIT", "")) {
            dailyLimit = vm.envUint("DAILY_LIMIT");
        }

        vm.startBroadcast();
        EnhancedWallet wallet = new EnhancedWallet(dailyLimit);
        vm.stopBroadcast();

        // Log deployment information
        console.log("EnhancedWallet deployed at:", address(wallet));
        console.log("Daily limit set to:", dailyLimit);
        
        return wallet;
    }
} 