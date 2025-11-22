// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {GuanacoHubOApp, MessagingFee} from "../src/GuanacoHubOApp.sol";
import {SimpleReceiver} from "../src/SimpleReceiver.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract TestArbitrumToBase is Script {
    using OptionsBuilder for bytes;

    address constant ENDPOINT_ARB = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant ENDPOINT_BASE = 0x1a44076050125825900e736c501f859c50fE728c;

    uint32 constant EID_ARB = 30110;
    uint32 constant EID_BASE = 30184;

    uint16 constant SEND = 1;
    uint128 constant GAS_LIMIT = 200000;

    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        uint256 arbFork = vm.createFork("arbitrum");
        uint256 baseFork = vm.createFork("base");

        console.log("=== Testing Arbitrum -> Base (Proven Pathway) ===");
        
        // Deploy Hub on Arbitrum
        vm.selectFork(arbFork);
        vm.startBroadcast(privateKey);
        GuanacoHubOApp hub = new GuanacoHubOApp(ENDPOINT_ARB, deployer);
        vm.stopBroadcast();
        console.log("Hub on Arbitrum:", address(hub));

        // Deploy Receiver on Base
        vm.selectFork(baseFork);
        vm.startBroadcast(privateKey);
        SimpleReceiver receiverBase = new SimpleReceiver(ENDPOINT_BASE, deployer);
        vm.stopBroadcast();
        console.log("Receiver on Base:", address(receiverBase));

        console.log("\n=== Setting Peers ===");
        vm.selectFork(arbFork);
        vm.startBroadcast(privateKey);
        hub.setPeer(EID_BASE, bytes32(uint256(uint160(address(receiverBase)))));
        vm.stopBroadcast();

        vm.selectFork(baseFork);
        vm.startBroadcast(privateKey);
        receiverBase.setPeer(EID_ARB, bytes32(uint256(uint160(address(hub)))));
        vm.stopBroadcast();

        console.log("\n=== Sending Test Message (Using Default DVNs) ===");
        vm.selectFork(arbFork);
        
        uint32[] memory dstEids = new uint32[](1);
        dstEids[0] = EID_BASE;

        string[] memory messages = new string[](1);
        messages[0] = "Hello Base from Arbitrum!";

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0);

        MessagingFee memory fee = hub.quote(dstEids, SEND, messages, options, false);
        console.log("Fee:", fee.nativeFee);

        vm.startBroadcast(privateKey);
        hub.send{value: fee.nativeFee}(dstEids, SEND, messages, options);
        vm.stopBroadcast();

        console.log("\n=== TEST COMPLETE ===");
        console.log("Hub (Arbitrum):", address(hub));
        console.log("Receiver (Base):", address(receiverBase));
        console.log("\nMessage sent using DEFAULT LayerZero DVNs!");
        console.log("This should work since Arbitrum<->Base is a proven pathway.");
        console.log("Check LayerZeroScan and Base receiver in ~2 minutes.");
    }
}

