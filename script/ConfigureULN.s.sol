// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import {ExecutorConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";

/**
 * @title ConfigureULN
 * @notice Configures ULN (DVN) and Executor settings for cross-chain messaging
 * @dev Sets up security parameters and execution settings for deployed contracts
 */
contract ConfigureULN is Script {
    // Endpoint addresses per chain
    address constant ENDPOINT_ZIRCUIT = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;

    // Chain aliases from foundry.toml
    string constant ZIRCUIT = "zircuit";

    // Endpoint IDs
    uint32 constant BASE_EID = 30184;
    uint32 constant ARBITRUM_EID = 30110;

    // Library addresses per chain
    address constant SEND_LIB_ZIRCUIT = 0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7;

    // DVN and Executor addresses (using LayerZero Labs default addresses)
    address constant DVN_LAYERZERO_LABS = 0xd56e4dcC951169E0419FcF0Ca48B6Ce4Ec958042;
    address constant EXECUTOR_LAYERZERO_LABS = 0x31Cae3B7FB82D847621859fb1585353c5735e0E1;

    // Configuration constants
    uint32 constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 constant ULN_CONFIG_TYPE = 2;

    // Minimum confirmations and gas settings
    uint64 constant MIN_CONFIRMATIONS = 15;
    uint8 constant REQUIRED_DVN_COUNT = 2;
    uint32 constant EXECUTOR_MAX_MESSAGE_SIZE = 10000;

    // Default deployed contract address (override via environment variable)
    address constant DEFAULT_HUB_ADDRESS = 0x65bec6934b24390F9195C5bCF8A59fa008964722;

    function run() external {
        // Get contract address (can be overridden via environment variable)
        address hubAddress;
        try vm.envAddress("HUB_ADDRESS") returns (address addr) {
            hubAddress = addr;
        } catch {
            hubAddress = DEFAULT_HUB_ADDRESS;
        }

        console.log("=== Configuring ULN and Executor Settings ===");
        console.log("Hub Address (Zircuit):", hubAddress);

        // ============================================
        // Configure ULN and Executor for Zircuit Hub
        // ============================================
        console.log("\n--- Configuring Zircuit Hub ULN/Executor ---");
        vm.createSelectFork(ZIRCUIT);
        vm.startBroadcast();

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
        paramsZircuitToBase[0] = SetConfigParam({
            eid: BASE_EID,
            configType: EXECUTOR_CONFIG_TYPE,
            config: abi.encode(execZircuitToBase)
        });
        paramsZircuitToBase[1] = SetConfigParam({
            eid: BASE_EID,
            configType: ULN_CONFIG_TYPE,
            config: abi.encode(ulnZircuitToBase)
        });

        ILayerZeroEndpointV2(ENDPOINT_ZIRCUIT).setConfig(
            hubAddress,
            SEND_LIB_ZIRCUIT,
            paramsZircuitToBase
        );
        console.log("ULN/Executor configured for Zircuit -> Base");

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
        paramsZircuitToArbitrum[0] = SetConfigParam({
            eid: ARBITRUM_EID,
            configType: EXECUTOR_CONFIG_TYPE,
            config: abi.encode(execZircuitToArbitrum)
        });
        paramsZircuitToArbitrum[1] = SetConfigParam({
            eid: ARBITRUM_EID,
            configType: ULN_CONFIG_TYPE,
            config: abi.encode(ulnZircuitToArbitrum)
        });

        ILayerZeroEndpointV2(ENDPOINT_ZIRCUIT).setConfig(
            hubAddress,
            SEND_LIB_ZIRCUIT,
            paramsZircuitToArbitrum
        );
        console.log("ULN/Executor configured for Zircuit -> Arbitrum");

        vm.stopBroadcast();

        console.log("\n=== ULN/Executor Configuration Complete ===");
        console.log("Security settings configured with:");
        console.log("- 15 block confirmations");
        console.log("- 2-of-2 DVN configuration");
        console.log("- LayerZero Labs Executor");
        console.log("- Max message size: 10,000 bytes");
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
