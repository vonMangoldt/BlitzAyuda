// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {GuanacoHubOApp} from "../src/GuanacoHubOApp.sol";
import {SimpleReceiver} from "../src/SimpleReceiver.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import {ExecutorConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";

/**
 * @title DeployAndConfigure
 * @notice Complete deployment and configuration script for GuanacoHubOApp and SimpleReceiver
 * @dev Deploys contracts, sets libraries, configures DVNs/Executors, and sets peers
 */
contract DeployAndConfigure is Script {
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

    // Library addresses per chain
    address constant SEND_LIB_ZIRCUIT = 0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7;
    address constant SEND_LIB_BASE = 0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2;
    address constant SEND_LIB_ARBITRUM = 0x975bcD720be66659e3EB3C0e4F1866a3020E493A;

    address constant RECEIVE_LIB_ZIRCUIT = 0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043;
    address constant RECEIVE_LIB_BASE = 0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf;
    address constant RECEIVE_LIB_ARBITRUM = 0x7B9E184e07a6EE1aC23eAe0fe8D6Be2f663f05e6;

    // DVN and Executor addresses (using LayerZero Labs default addresses)
    address constant DVN_LAYERZERO_LABS = 0xd56e4dcC951169E0419FcF0Ca48B6Ce4Ec958042;
    address constant EXECUTOR_LAYERZERO_LABS = 0x31Cae3B7FB82D847621859fb1585353c5735e0E1;

    // Configuration constants
    uint32 constant GRACE_PERIOD = 0;
    uint32 constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 constant ULN_CONFIG_TYPE = 2;

    // Minimum confirmations and gas settings
    uint64 constant MIN_CONFIRMATIONS = 15;
    uint8 constant REQUIRED_DVN_COUNT = 2;
    uint32 constant EXECUTOR_MAX_MESSAGE_SIZE = 10000;

    struct Deployment {
        address hubAddress;
        address receiverBaseAddress;
        address receiverArbitrumAddress;
    }

    function run() external returns (Deployment memory deployment) {
        address deployer = msg.sender;

        console.log("=== Starting Complete Deployment and Configuration ===");
        console.log("Deployer address:", deployer);

        // ============================================
        // PHASE 1: Deploy Contracts
        // ============================================
        console.log("\n=== PHASE 1: Deploying Contracts ===");

        // Deploy SimpleReceiver to Base
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

        // Deploy SimpleReceiver to Arbitrum
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

        // Deploy GuanacoHubOApp to Zircuit
        console.log("\n--- Deploying to Zircuit ---");
        vm.createSelectFork(ZIRCUIT);
        vm.startBroadcast(deployer);

        GuanacoHubOApp hub = new GuanacoHubOApp(
            LZ_ENDPOINT_ZIRCUIT,
            deployer
        );

        vm.stopBroadcast();

        // Set peers - need to do this in separate broadcast blocks
        console.log("\n--- Setting peers ---");

        // Set peers on hub
        vm.startBroadcast(deployer);
        hub.setPeer(BASE_EID, bytes32(uint256(uint160(address(receiverBase)))));
        hub.setPeer(ARBITRUM_EID, bytes32(uint256(uint160(address(receiverArbitrum)))));
        vm.stopBroadcast();

        // Set peer on Base receiver
        vm.createSelectFork(BASE);
        vm.startBroadcast(deployer);
        SimpleReceiver(address(receiverBase)).setPeer(ZIRCUIT_EID, bytes32(uint256(uint160(address(hub)))));
        vm.stopBroadcast();

        // Set peer on Arbitrum receiver
        vm.createSelectFork(ARBITRUM);
        vm.startBroadcast(deployer);
        SimpleReceiver(address(receiverArbitrum)).setPeer(ZIRCUIT_EID, bytes32(uint256(uint160(address(hub)))));
        vm.stopBroadcast();
        deployment.hubAddress = address(hub);
        console.log("GuanacoHubOApp deployed to Zircuit at:", address(hub));

        // ============================================
        // PHASE 2: Configure Libraries
        // ============================================
        console.log("\n=== PHASE 2: Configuring Libraries ===");

        // Configure Zircuit Hub
        console.log("\n--- Configuring Zircuit Hub Libraries ---");
        vm.createSelectFork(ZIRCUIT);
        vm.startBroadcast(deployer);

        // Send libraries (Zircuit -> Base and Arbitrum)
        ILayerZeroEndpointV2(LZ_ENDPOINT_ZIRCUIT).setSendLibrary(
            address(hub), BASE_EID, SEND_LIB_ZIRCUIT
        );
        ILayerZeroEndpointV2(LZ_ENDPOINT_ZIRCUIT).setSendLibrary(
            address(hub), ARBITRUM_EID, SEND_LIB_ZIRCUIT
        );

        // Receive libraries (Zircuit <- Base and Arbitrum)
        ILayerZeroEndpointV2(LZ_ENDPOINT_ZIRCUIT).setReceiveLibrary(
            address(hub), BASE_EID, RECEIVE_LIB_ZIRCUIT, GRACE_PERIOD
        );
        ILayerZeroEndpointV2(LZ_ENDPOINT_ZIRCUIT).setReceiveLibrary(
            address(hub), ARBITRUM_EID, RECEIVE_LIB_ZIRCUIT, GRACE_PERIOD
        );

        vm.stopBroadcast();

        // Configure Base Receiver
        console.log("\n--- Configuring Base Receiver Libraries ---");
        vm.createSelectFork(BASE);
        vm.startBroadcast(deployer);

        // Send library (Base -> Zircuit)
        ILayerZeroEndpointV2(LZ_ENDPOINT_BASE).setSendLibrary(
            address(receiverBase), ZIRCUIT_EID, SEND_LIB_BASE
        );

        // Receive library (Base <- Zircuit)
        ILayerZeroEndpointV2(LZ_ENDPOINT_BASE).setReceiveLibrary(
            address(receiverBase), ZIRCUIT_EID, RECEIVE_LIB_BASE, GRACE_PERIOD
        );

        vm.stopBroadcast();

        // Configure Arbitrum Receiver
        console.log("\n--- Configuring Arbitrum Receiver Libraries ---");
        vm.createSelectFork(ARBITRUM);
        vm.startBroadcast(deployer);

        // Send library (Arbitrum -> Zircuit)
        ILayerZeroEndpointV2(LZ_ENDPOINT_ARBITRUM).setSendLibrary(
            address(receiverArbitrum), ZIRCUIT_EID, SEND_LIB_ARBITRUM
        );

        // Receive library (Arbitrum <- Zircuit)
        ILayerZeroEndpointV2(LZ_ENDPOINT_ARBITRUM).setReceiveLibrary(
            address(receiverArbitrum), ZIRCUIT_EID, RECEIVE_LIB_ARBITRUM, GRACE_PERIOD
        );

        vm.stopBroadcast();

        // ============================================
        // PHASE 3: Configure ULN and Executor Settings
        // ============================================
        console.log("\n=== PHASE 3: Configuring ULN and Executor Settings ===");

        // Configure Zircuit Hub
        console.log("\n--- Configuring Zircuit Hub ULN/Executor ---");
        vm.createSelectFork(ZIRCUIT);
        vm.startBroadcast(deployer);

        // ULN Config for Zircuit -> Base
        UlnConfig memory ulnZircuitToBase = UlnConfig({
            confirmations: MIN_CONFIRMATIONS,
            requiredDVNCount: REQUIRED_DVN_COUNT,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: _getDefaultDVNs(),
            optionalDVNs: new address[](0)
        });

        // Executor Config for Zircuit -> Base
        ExecutorConfig memory execZircuitToBase = ExecutorConfig({
            maxMessageSize: EXECUTOR_MAX_MESSAGE_SIZE,
            executor: EXECUTOR_LAYERZERO_LABS
        });

        SetConfigParam[] memory paramsZircuitToBase = new SetConfigParam[](2);
        paramsZircuitToBase[0] = SetConfigParam(BASE_EID, EXECUTOR_CONFIG_TYPE, abi.encode(execZircuitToBase));
        paramsZircuitToBase[1] = SetConfigParam(BASE_EID, ULN_CONFIG_TYPE, abi.encode(ulnZircuitToBase));

        ILayerZeroEndpointV2(LZ_ENDPOINT_ZIRCUIT).setConfig(
            address(hub), SEND_LIB_ZIRCUIT, paramsZircuitToBase
        );

        // ULN Config for Zircuit -> Arbitrum
        UlnConfig memory ulnZircuitToArbitrum = UlnConfig({
            confirmations: MIN_CONFIRMATIONS,
            requiredDVNCount: REQUIRED_DVN_COUNT,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: _getDefaultDVNs(),
            optionalDVNs: new address[](0)
        });

        // Executor Config for Zircuit -> Arbitrum
        ExecutorConfig memory execZircuitToArbitrum = ExecutorConfig({
            maxMessageSize: EXECUTOR_MAX_MESSAGE_SIZE,
            executor: EXECUTOR_LAYERZERO_LABS
        });

        SetConfigParam[] memory paramsZircuitToArbitrum = new SetConfigParam[](2);
        paramsZircuitToArbitrum[0] = SetConfigParam(ARBITRUM_EID, EXECUTOR_CONFIG_TYPE, abi.encode(execZircuitToArbitrum));
        paramsZircuitToArbitrum[1] = SetConfigParam(ARBITRUM_EID, ULN_CONFIG_TYPE, abi.encode(ulnZircuitToArbitrum));

        ILayerZeroEndpointV2(LZ_ENDPOINT_ZIRCUIT).setConfig(
            address(hub), SEND_LIB_ZIRCUIT, paramsZircuitToArbitrum
        );

        vm.stopBroadcast();

        // ============================================
        // PHASE 4: Summary
        // ============================================
        console.log("\n=== DEPLOYMENT AND CONFIGURATION COMPLETE ===");
        console.log("Zircuit Hub:", deployment.hubAddress);
        console.log("Base Receiver:", deployment.receiverBaseAddress);
        console.log("Arbitrum Receiver:", deployment.receiverArbitrumAddress);
        console.log("\nAll contracts deployed and configured!");
        console.log("You can now send batch messages from the hub to both receivers.");

        return deployment;
    }

    /**
     * @dev Get default DVN addresses (LayerZero Labs)
     */
    function _getDefaultDVNs() internal pure returns (address[] memory) {
        address[] memory dvns = new address[](2);
        dvns[0] = DVN_LAYERZERO_LABS;
        dvns[1] = DVN_LAYERZERO_LABS; // Using same DVN for both required slots
        return dvns;
    }
}
