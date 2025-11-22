// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

/**
 * @title SetLibraries
 * @notice Sets up send and receive libraries for OApp messaging across multiple chains
 * @dev Configures libraries for Zircuit hub and Base/Arbitrum receivers
 */
contract SetLibraries is Script {
    // Endpoint addresses per chain
    address constant ENDPOINT_ZIRCUIT = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;
    address constant ENDPOINT_BASE = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant ENDPOINT_ARBITRUM = 0x1a44076050125825900e736c501f859c50fE728c;

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

    // Grace period for library switch (0 for immediate, or block number for gradual migration)
    uint32 constant GRACE_PERIOD = 0;

    // Default deployed contract addresses (override via environment variables)
    address constant DEFAULT_HUB_ADDRESS = 0x65bec6934b24390F9195C5bCF8A59fa008964722;
    address constant DEFAULT_RECEIVER_BASE = 0xBb1C71B5668a24E04486Fe5fcb54cF18B1664Ee9;
    address constant DEFAULT_RECEIVER_ARBITRUM = 0x65bec6934b24390F9195C5bCF8A59fa008964722;

    function run() external {
        // Get contract addresses (can be overridden via environment variables)
        address hubAddress;
        try vm.envAddress("HUB_ADDRESS") returns (address addr) {
            hubAddress = addr;
        } catch {
            hubAddress = DEFAULT_HUB_ADDRESS;
        }

        address receiverBase;
        try vm.envAddress("RECEIVER_BASE") returns (address addr) {
            receiverBase = addr;
        } catch {
            receiverBase = DEFAULT_RECEIVER_BASE;
        }

        address receiverArbitrum;
        try vm.envAddress("RECEIVER_ARBITRUM") returns (address addr) {
            receiverArbitrum = addr;
        } catch {
            receiverArbitrum = DEFAULT_RECEIVER_ARBITRUM;
        }

        console.log("=== Setting up Libraries ===");
        console.log("Hub Address (Zircuit):", hubAddress);
        console.log("Receiver Base:", receiverBase);
        console.log("Receiver Arbitrum:", receiverArbitrum);

        // ============================================
        // Configure Zircuit Hub
        // ============================================
        console.log("\n=== Configuring Zircuit Hub ===");
        vm.createSelectFork("zircuit");
        
        // Set send libraries from Zircuit to Base and Arbitrum
        console.log("Setting send library: Zircuit -> Base");
        vm.startBroadcast();
        ILayerZeroEndpointV2(ENDPOINT_ZIRCUIT).setSendLibrary(
            hubAddress,
            BASE_EID,
            SEND_LIB_ZIRCUIT
        );

        console.log("Setting send library: Zircuit -> Arbitrum");
        ILayerZeroEndpointV2(ENDPOINT_ZIRCUIT).setSendLibrary(
            hubAddress,
            ARBITRUM_EID,
            SEND_LIB_ZIRCUIT
        );

        // Set receive libraries for messages coming to Zircuit from Base and Arbitrum
        console.log("Setting receive library: Zircuit <- Base");
        ILayerZeroEndpointV2(ENDPOINT_ZIRCUIT).setReceiveLibrary(
            hubAddress,
            BASE_EID,
            RECEIVE_LIB_ZIRCUIT,
            GRACE_PERIOD
        );

        console.log("Setting receive library: Zircuit <- Arbitrum");
        ILayerZeroEndpointV2(ENDPOINT_ZIRCUIT).setReceiveLibrary(
            hubAddress,
            ARBITRUM_EID,
            RECEIVE_LIB_ZIRCUIT,
            GRACE_PERIOD
        );
        vm.stopBroadcast();

        // ============================================
        // Configure Base Receiver
        // ============================================
        console.log("\n=== Configuring Base Receiver ===");
        vm.createSelectFork("base");

        // Set send library from Base to Zircuit
        console.log("Setting send library: Base -> Zircuit");
        vm.startBroadcast();
        ILayerZeroEndpointV2(ENDPOINT_BASE).setSendLibrary(
            receiverBase,
            ZIRCUIT_EID,
            SEND_LIB_BASE
        );

        // Set receive library for messages coming to Base from Zircuit
        console.log("Setting receive library: Base <- Zircuit");
        ILayerZeroEndpointV2(ENDPOINT_BASE).setReceiveLibrary(
            receiverBase,
            ZIRCUIT_EID,
            RECEIVE_LIB_BASE,
            GRACE_PERIOD
        );
        vm.stopBroadcast();

        // ============================================
        // Configure Arbitrum Receiver
        // ============================================
        console.log("\n=== Configuring Arbitrum Receiver ===");
        vm.createSelectFork("arbitrum");

        // Set send library from Arbitrum to Zircuit
        console.log("Setting send library: Arbitrum -> Zircuit");
        vm.startBroadcast();
        ILayerZeroEndpointV2(ENDPOINT_ARBITRUM).setSendLibrary(
            receiverArbitrum,
            ZIRCUIT_EID,
            SEND_LIB_ARBITRUM
        );

        // Set receive library for messages coming to Arbitrum from Zircuit
        console.log("Setting receive library: Arbitrum <- Zircuit");
        ILayerZeroEndpointV2(ENDPOINT_ARBITRUM).setReceiveLibrary(
            receiverArbitrum,
            ZIRCUIT_EID,
            RECEIVE_LIB_ARBITRUM,
            GRACE_PERIOD
        );
        vm.stopBroadcast();

        console.log("\n=== Library Configuration Complete ===");
        console.log("All libraries have been set successfully!");
    }
}

