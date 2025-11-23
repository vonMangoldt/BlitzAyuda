// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {GuanacoOApp, MessagingFee} from "../src/GuanacoOApp.sol";
import {GuanacoComposer} from "../src/GuanacoComposer.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract TestSendTx is Script {
    using OptionsBuilder for bytes;

    address constant OAPP_ZIRCUIT = 0x1DE44115c80FCdCf74085e9f554075178881e2f2;
    address constant OAPP_BASE = 0xd263123785EA544eDC363147a657DF613c430db4;
    address constant OAPP_ARBITRUM = 0x084bE0E911FD350F42A036e44989f2748F176Eb9;

    address constant ENDPOINT_ZIRCUIT = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;
    address constant ENDPOINT_ARB = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant ENDPOINT_BASE = 0x1a44076050125825900e736c501f859c50fE728c;

    uint32 constant EID_ARB = 30110;
    uint32 constant EID_BASE = 30184;

    uint16 constant SEND = 1;
    uint128 constant GAS_LIMIT = 200000;

    function run() external {
        address deployer = 0xF6063cdF296412d55dd9930F183eBd0b53e964C2;

        uint256 zircuitFork = vm.createFork("zircuit");
        uint256 baseFork = vm.createFork("base");
        uint256 arbFork = vm.createFork("arbitrum");

        console.log("=== Testing Zircuit -> Base and Arbitrum ===");

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

        vm.selectFork(zircuitFork);
        GuanacoOApp hub = GuanacoOApp(OAPP_ZIRCUIT);
        
        uint32[] memory dstEids = new uint32[](2);
        dstEids[0] = EID_BASE;
        dstEids[1] = EID_ARB;

        bytes[] memory messagesForQuoting = new bytes[](2);
        messagesForQuoting[0] = abi.encode(msg.sender, "0 Hello Base from Zircuit!");
        messagesForQuoting[1] = abi.encode(msg.sender, "1 Hello Arbitrum from Zircuit!");

        bytes[] memory messages = new bytes[](2);
        messages[0] = abi.encode("0 Hello Base from Zircuit!");
        messages[1] = abi.encode("1 Hello Arbitrum from Zircuit!");

        bytes[] memory options = new bytes[](2);
        options[0] = OptionsBuilder.newOptions()
            .addExecutorLzReceiveOption(GAS_LIMIT, 0)
            .addExecutorLzComposeOption(0, GAS_LIMIT, 0);
        options[1] = OptionsBuilder.newOptions()
            .addExecutorLzReceiveOption(GAS_LIMIT, 0)
            .addExecutorLzComposeOption(0, GAS_LIMIT, 0);

        MessagingFee memory fee = hub.quote(dstEids, SEND, messagesForQuoting, options, false);
        console.log("Fee:", fee.nativeFee);

        vm.startBroadcast();
        hub.send{value: fee.nativeFee}(dstEids, SEND, messages, options);
        vm.stopBroadcast();

        console.log("\n=== TEST COMPLETE ===");
    }
}

