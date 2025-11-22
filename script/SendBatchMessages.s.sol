// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {GuanacoHubOApp, MessagingFee} from "../src/GuanacoHubOApp.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

/**
 * @title SendBatchMessages
 * @notice Script to send batch messages from Zircuit hub to Base and Arbitrum
 * @dev Interacts with deployed GuanacoHubOApp contract on Zircuit
 */
contract SendBatchMessages is Script {
    using OptionsBuilder for bytes;

    // Deployed contract address on Zircuit
    address constant HUB_ADDRESS = 0x65bec6934b24390F9195C5bCF8A59fa008964722;

    // Chain aliases
    string constant ZIRCUIT = "zircuit";

    // Endpoint IDs
    uint32 constant BASE_EID = 30184;
    uint32 constant ARBITRUM_EID = 30110;

    // Message type
    uint16 constant SEND = 1;

    // Gas limit for executor on destination chains (adjust as needed)
    uint128 constant EXECUTOR_GAS_LIMIT = 200000;

    function run() external {
        // Connect to Zircuit
        vm.createSelectFork(ZIRCUIT);
        
        // Get the deployed contract
        GuanacoHubOApp hub = GuanacoHubOApp(HUB_ADDRESS);
        
        console.log("Hub contract address:", HUB_ADDRESS);

        // Prepare batch send parameters
        uint32[] memory dstEids = new uint32[](2);
        dstEids[0] = BASE_EID;
        dstEids[1] = ARBITRUM_EID;

        string[] memory messages = new string[](2);
        messages[0] = "Hello Base";
        messages[1] = "Hello Arbitrum";

        // Build options with executor gas for lzReceive
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(
            EXECUTOR_GAS_LIMIT,
            0 // no native value to send
        );

        console.log("\n=== Preparing Batch Send ===");
        console.log("Destination EIDs:");
        console.log("  - Base:", BASE_EID);
        console.log("  - Arbitrum:", ARBITRUM_EID);
        console.log("Messages:");
        console.log("  - To Base:", messages[0]);
        console.log("  - To Arbitrum:", messages[1]);
        console.log("Executor Gas Limit:", EXECUTOR_GAS_LIMIT);

        // Quote the fee
        console.log("\n=== Quoting Fee ===");
        MessagingFee memory totalFee = hub.quote(
            dstEids,
            SEND,
            messages,
            options,
            false
        );

        console.log("Total Native Fee:", totalFee.nativeFee);
        console.log("Total LZ Token Fee:", totalFee.lzTokenFee);

        // Send the batch messages
        console.log("\n=== Sending Batch Messages ===");
        vm.startBroadcast();

        hub.send{value: totalFee.nativeFee}(
            dstEids,
            SEND,
            messages,
            options
        );

        vm.stopBroadcast();

        console.log("\n=== Batch Send Complete ===");
        console.log("Messages sent successfully!");
        console.log("Check the receivers on Base and Arbitrum for the messages.");
    }
}

