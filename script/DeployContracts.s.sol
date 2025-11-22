// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {GuanacoHubOApp} from "../src/GuanacoHubOApp.sol";
import {SimpleReceiver} from "../src/SimpleReceiver.sol";

/**
 * @title DeployContracts
 * @notice Deployment script for GuanacoHubOApp and SimpleReceiver contracts
 * @dev Deploys contracts across multiple chains and sets up peers
 */
contract DeployContracts is Script {
    // LayerZero Endpoint addresses per chain
    address constant LZ_ENDPOINT_ZIRCUIT = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;
    address constant LZ_ENDPOINT_BASE = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant LZ_ENDPOINT_ARBITRUM = 0x1a44076050125825900e736c501f859c50fE728c;

    // Chain aliases from foundry.toml
    string constant ZIRCUIT = "zircuit";
    string constant BASE = "base";
    string constant ARBITRUM = "arbitrum";

    // Endpoint IDs
    uint32 constant ZIRCUIT_EID = 30303;
    uint32 constant BASE_EID = 30184;
    uint32 constant ARBITRUM_EID = 30110;

    struct Deployment {
        address hubAddress;
        address receiverBaseAddress;
        address receiverArbitrumAddress;
    }

    function run() external returns (Deployment memory deployment) {
        address deployer = 0xF6063cdF296412d55dd9930F183eBd0b53e964C2;

        console.log("=== Starting Contract Deployment ===");
        console.log("Deployer address:", deployer);

        // ============================================
        // Deploy SimpleReceiver to Base
        // ============================================
        console.log("\n--- Deploying to Base ---");
        vm.createSelectFork(BASE);
        vm.startBroadcast(deployer);

        SimpleReceiver receiverBase = new SimpleReceiver(
            LZ_ENDPOINT_BASE,
            deployer
        );

        vm.stopBroadcast();
        deployment.receiverBaseAddress = address(receiverBase);
        console.log("SimpleReceiver deployed to Base at:", address(receiverBase));

        // ============================================
        // Deploy SimpleReceiver to Arbitrum
        // ============================================
        console.log("\n--- Deploying to Arbitrum ---");
        vm.createSelectFork(ARBITRUM);
        vm.startBroadcast(deployer);

        SimpleReceiver receiverArbitrum = new SimpleReceiver(
            LZ_ENDPOINT_ARBITRUM,
            deployer
        );

        vm.stopBroadcast();
        deployment.receiverArbitrumAddress = address(receiverArbitrum);
        console.log("SimpleReceiver deployed to Arbitrum at:", address(receiverArbitrum));

        // ============================================
        // Deploy GuanacoHubOApp to Zircuit
        // ============================================
        console.log("\n--- Deploying to Zircuit ---");
        vm.createSelectFork(ZIRCUIT);
        vm.startBroadcast(deployer);

        GuanacoHubOApp hub = new GuanacoHubOApp(
            LZ_ENDPOINT_ZIRCUIT,
            deployer
        );

        vm.stopBroadcast();
        deployment.hubAddress = address(hub);
        console.log("GuanacoHubOApp deployed to Zircuit at:", address(hub));

        // ============================================
        // Set Peers (Bidirectional)
        // ============================================
        console.log("\n--- Setting Peers ---");

        // Set peers on hub (Zircuit -> Base and Arbitrum)
        vm.startBroadcast(deployer);
        hub.setPeer(BASE_EID, bytes32(uint256(uint160(address(receiverBase)))));
        hub.setPeer(ARBITRUM_EID, bytes32(uint256(uint160(address(receiverArbitrum)))));
        vm.stopBroadcast();
        console.log("Hub peers set for Base and Arbitrum");

        // Set peer on Base receiver (Base -> Zircuit)
        vm.createSelectFork(BASE);
        vm.startBroadcast(deployer);
        SimpleReceiver(address(receiverBase)).setPeer(ZIRCUIT_EID, bytes32(uint256(uint160(address(hub)))));
        vm.stopBroadcast();
        console.log("Base receiver peer set for Zircuit");

        // Set peer on Arbitrum receiver (Arbitrum -> Zircuit)
        vm.createSelectFork(ARBITRUM);
        vm.startBroadcast(deployer);
        SimpleReceiver(address(receiverArbitrum)).setPeer(ZIRCUIT_EID, bytes32(uint256(uint160(address(hub)))));
        vm.stopBroadcast();
        console.log("Arbitrum receiver peer set for Zircuit");

        // ============================================
        // Summary
        // ============================================
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("Zircuit Hub:", deployment.hubAddress);
        console.log("Base Receiver:", deployment.receiverBaseAddress);
        console.log("Arbitrum Receiver:", deployment.receiverArbitrumAddress);
        console.log("\nAll contracts deployed and peers configured!");
        console.log("Next step: Run SetLibraries.s.sol to configure message libraries");

        return deployment;
    }
}
