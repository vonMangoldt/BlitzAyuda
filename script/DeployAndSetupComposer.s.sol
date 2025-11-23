// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {GuanacoOApp, MessagingFee} from "../src/GuanacoOApp.sol";
import {GuanacoComposer} from "../src/GuanacoComposer.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract DeployAndSetupComposer is Script {
    address constant OAPP_ZIRCUIT = 0xd36ea10Cb394a13a0BF5a46aB88a37E0C95Af7Ac;
    address constant OAPP_BASE = 0x536271fB18C1D3CD4FCaf4F04fB0513a83961c1A;
    address constant OAPP_ARBITRUM = 0xF802DB56c7C430b564E2B22761b724588374037C;

    address constant ENDPOINT_ARB = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant ENDPOINT_BASE = 0x1a44076050125825900e736c501f859c50fE728c;

    function run() external {
        uint256 baseFork = vm.createFork("base");
        uint256 arbFork = vm.createFork("arbitrum");

        console.log("=== Setting up Composer on Base and Arbitrum ===");

        // Deployer composer on destination chains
        vm.selectFork(baseFork);
        vm.startBroadcast();
        GuanacoComposer composerBase = new GuanacoComposer(OAPP_BASE, ENDPOINT_BASE);
        GuanacoOApp(OAPP_BASE).setComposer(address(composerBase));
        console.log("Composer:", address(composerBase), "on Base");
        vm.stopBroadcast();

        vm.selectFork(arbFork);
        vm.startBroadcast();
        GuanacoComposer composerArbitrum = new GuanacoComposer(OAPP_ARBITRUM, ENDPOINT_ARB);
        GuanacoOApp(OAPP_ARBITRUM).setComposer(address(composerArbitrum));
        console.log("Composer:", address(composerArbitrum), "on Arbitrum");
        vm.stopBroadcast();
    }
}

