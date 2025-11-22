// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {GuanacoHubOApp} from "../src/GuanacoHubOApp.sol";
import {SimpleReceiver} from "../src/SimpleReceiver.sol";
import { UlnConfig } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";

/**
 * @title DeployMultiChain
 * @notice Deployment script for deploying GuanacoHubOApp to Zircuit and SimpleReceiver to Base and Arbitrum
 * @dev Uses vm.createSelectFork to switch between chains during deployment
 */
contract DeployMultiChain is Script {
    address constant DEFAULT_LZ_ENDPOINT_ZIRCUIT = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;
    address constant DEFAULT_LZ_ENDPOINT_BASE = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant DEFAULT_LZ_ENDPOINT_ARBITRUM = 0x1a44076050125825900e736c501f859c50fE728c;

    // Chain aliases from foundry.toml
    string constant ZIRCUIT = "zircuit";
    string constant BASE = "base";
    string constant ARBITRUM = "arbitrum";

    uint32 constant ZIRCUIT_EID = 30303;
    uint32 constant BASE_EID = 30184;
    uint32 constant ARBITRUM_EID = 30110;

    // libraries
    address constant DEFAULT_LZ_SEND_LIBRARY_ZIRCUIT = 0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7;
    address constant DEFAULT_LZ_SEND_LIBRARY_BASE = 0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2;
    address constant DEFAULT_LZ_SEND_LIBRARY_ARBITRUM = 0x975bcD720be66659e3EB3C0e4F1866a3020E493A;

    address constant DEFAULT_LZ_RECEIVE_LIBRARY_ZIRCUIT = 0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043;
    address constant DEFAULT_LZ_RECEIVE_LIBRARY_BASE = 0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf;
    address constant DEFAULT_LZ_RECEIVE_LIBRARY_ARBITRUM = 0x7B9E184e07a6EE1aC23eAe0fe8D6Be2f663f05e6;

    struct Deployment {
        address hubAddress;
        address receiverBaseAddress;
        address receiverArbitrumAddress;
    }

    function run() external returns (Deployment memory deployment) {
        address deployer = msg.sender;

        console.log("Deployer address:", deployer);

        // Deploy SimpleReceiver to Base
        console.log("\n=== Deploying to Base ===");
        vm.createSelectFork(BASE);
        vm.startBroadcast();
        
        SimpleReceiver receiverBase = new SimpleReceiver(
            DEFAULT_LZ_ENDPOINT_BASE,
            deployer
        );
        
        vm.stopBroadcast();
        deployment.receiverBaseAddress = address(receiverBase);
        console.log("SimpleReceiver deployed to Base at:", address(receiverBase));

        // Deploy SimpleReceiver to Arbitrum
        console.log("\n=== Deploying to Arbitrum ===");
        vm.createSelectFork(ARBITRUM);
        vm.startBroadcast();
        
        SimpleReceiver receiverArbitrum = new SimpleReceiver(
            DEFAULT_LZ_ENDPOINT_ARBITRUM,
            deployer
        );
        
        vm.stopBroadcast();
        deployment.receiverArbitrumAddress = address(receiverArbitrum);
        console.log("SimpleReceiver deployed to Arbitrum at:", address(receiverArbitrum));

        // Deploy GuanacoHubOApp to Zircuit
        console.log("\n=== Deploying to Zircuit ===");
        vm.createSelectFork(ZIRCUIT);
        vm.startBroadcast();
        
        GuanacoHubOApp hub = new GuanacoHubOApp(
            DEFAULT_LZ_ENDPOINT_ZIRCUIT,
            deployer
        );
        
        deployment.hubAddress = address(hub);

        hub.setPeer(BASE_EID, bytes32(uint256(uint160(address(receiverBase)))));
        hub.setPeer(ARBITRUM_EID, bytes32(uint256(uint160(address(receiverArbitrum)))));
        vm.stopBroadcast();

        // Summary
        console.log("\n=== Deployment Summary ===");
        console.log("Zircuit Hub:", deployment.hubAddress);
        console.log("Base Receiver:", deployment.receiverBaseAddress);
        console.log("Arbitrum Receiver:", deployment.receiverArbitrumAddress);

        return deployment;
    }
}

