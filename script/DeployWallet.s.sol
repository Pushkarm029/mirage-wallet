// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MirageWallet} from "../src/Wallet.sol";

contract DeployWallet is Script {
    function run() external returns (MirageWallet) {
        vm.startBroadcast();
        MirageWallet wallet = new MirageWallet();
        vm.stopBroadcast();

        return wallet;
    }
}
