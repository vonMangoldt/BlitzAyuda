// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Vm} from "forge-std/Vm.sol";

// Interfaces
interface IGuanacoOApp {
    struct MessagingFee {
        uint256 nativeFee;
        uint256 lzTokenFee;
    }
    function quote(
        uint32[] memory _dstEids,
        uint16 _msgType,
        bytes[] memory _messages,
        bytes[] calldata _extraSendOptions,
        bool _payInLzToken
    ) external view returns (MessagingFee memory totalFee);

    function send(
        uint32[] memory _dstEids,
        uint16 _msgType,
        bytes[] memory _messages,
        bytes[] calldata _extraSendOptions
    ) external payable;
    
    function SEND() external view returns (uint16);
}

interface IEIP7702DeleGator {
    struct Execution {
        address target;
        uint256 value;
        bytes callData;
    }
    function execute(bytes32 mode, bytes calldata executionCalldata) external payable;
    function setEmergencyTriggerWallet(address _emergencyTriggerWallet) external;
    function setSecurityAddress(address _securityAddress) external;
}

contract FinalTest is Script {
    using OptionsBuilder for bytes;

    // Addresses
    address constant DEPLOYER_DELEGATOR = 0xB9335E2433E2e51cE10aCF37Bc02dFeb5E16e688;
    address constant TRIGGER_WALLET = 0x0b6b2F0046eC9386003190E2bF6BBf5DA7F6C3D1;
    address constant SECURITY_WALLET = 0xa3b02B8d40230e806e0ec12F6429EBC772E1e8C4;

    address constant DELEGATION_IMPLEMENTATION_ZIRCUIT = 0x602B256097C5C00c45d0f1b7f75474B66BE17747;
    address constant DELEGATION_IMPLEMENTATION_L2 = 0x1FeA6d71644272Bda56b5D2fAd3A72B9967D5Ac3;

    address constant OAPP_ZIRCUIT = 0xd36ea10Cb394a13a0BF5a46aB88a37E0C95Af7Ac;
    address constant OAPP_BASE = 0x536271fB18C1D3CD4FCaf4F04fB0513a83961c1A;
    address constant OAPP_ARB = 0xF802DB56c7C430b564E2B22761b724588374037C;
    
    address constant COMPOSER_BASE = 0x77Fa754D756556b57422b62D3332654fcA32cf2f;
    address constant COMPOSER_ARB = 0x21a0c3A154C0a0B7c0E0f356196Bc83c205d9171;

    // Token Addresses
    address constant ZRC_WETH = 0x4200000000000000000000000000000000000006;
    address constant ZRC_TOKEN = 0xfd418e42783382E86Ae91e445406600Ba144D162;
    
    address constant BASE_WETH = 0x4200000000000000000000000000000000000006;
    address constant BASE_ZBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
    
    address constant ARB_WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant ARB_GRAPHITE = 0x440017A1b021006d556d7fc06A54c32E42Eb745B;

    // EIDs
    uint32 constant EID_BASE = 30184;
    uint32 constant EID_ARB = 30110;
    
    uint16 constant SEND = 1;
    uint128 constant GAS_LIMIT = 1000000;

    bytes32 constant BATCH_MODE = bytes32(uint256(1) << 248);

    // Structs for helpers
    struct QuoteParams {
        uint32[] dstEids;
        bytes[] messages;
        bytes[] options;
    }

    function run() external {
        uint256 triggerPk = vm.envUint("PRIVATE_KEY_TRIGGER_WALLET");
        uint256 delegatorPk = vm.envUint("PRIVATE_KEY"); // Used for 7702 signing

        console.log("=== Starting Multi-Chain Final Test ===");
        console.log("Deployer Delegator:", DEPLOYER_DELEGATOR);
        console.log("Trigger Wallet:", TRIGGER_WALLET);

        // 1. BASE Setup
//        vm.createSelectFork(vm.envString("BASE_RPC"));
//        console.log("--- Switched to BASE ---");
        
  //      vm.startBroadcast(delegatorPk);

  //      vm.signAndAttachDelegation(DELEGATION_IMPLEMENTATION_L2, delegatorPk);
   //     IEIP7702DeleGator(DEPLOYER_DELEGATOR).setEmergencyTriggerWallet(COMPOSER_BASE);
   //     IEIP7702DeleGator(DEPLOYER_DELEGATOR).setSecurityAddress(SECURITY_WALLET);
     //   vm.stopBroadcast();
     //   console.log("Base Setup Complete: Whitelisted Composer as Trigger, Set Security Addr");

        // 2. ARBITRUM Setup
     //   vm.createSelectFork(vm.envString("ARBITRUM_RPC"));
     //   console.log("--- Switched to ARBITRUM ---");

  //      vm.startBroadcast(delegatorPk);

   //     vm.signAndAttachDelegation(DELEGATION_IMPLEMENTATION_L2, delegatorPk);
   //     IEIP7702DeleGator(DEPLOYER_DELEGATOR).setEmergencyTriggerWallet(COMPOSER_ARB);
   //     IEIP7702DeleGator(DEPLOYER_DELEGATOR).setSecurityAddress(SECURITY_WALLET);
   //     vm.stopBroadcast();
   //     console.log("Arbitrum Setup Complete: Whitelisted Composer as Trigger, Set Security Addr");

        // 3. ZIRCUIT Setup & Execution
        vm.createSelectFork(vm.envString("ZIRCUIT_RPC"));
        console.log("--- Switched to ZIRCUIT ---");

        // 3a. Zircuit Setup
     //   vm.startBroadcast(delegatorPk);

     //   vm.signAndAttachDelegation(DELEGATION_IMPLEMENTATION_ZIRCUIT, delegatorPk);
     //   IEIP7702DeleGator(DEPLOYER_DELEGATOR).setEmergencyTriggerWallet(TRIGGER_WALLET);
     //   IEIP7702DeleGator(DEPLOYER_DELEGATOR).setSecurityAddress(SECURITY_WALLET);
     //   vm.stopBroadcast();
        console.log("Zircuit Setup Complete: Whitelisted Trigger Wallet, Set Security Addr");

        // 3b. Quote & Execution Logic
        // Construct Quote Params
        QuoteParams memory params = _buildQuoteParams();

        // Get Fee
        IGuanacoOApp hub = IGuanacoOApp(OAPP_ZIRCUIT);
        IGuanacoOApp.MessagingFee memory fee = hub.quote(
            params.dstEids, 
            SEND, 
            params.messages, 
            params.options, 
            false
        );
        console.log("Quote Fee:", fee.nativeFee);

        // Construct Execution Calldata
        bytes memory executionCalldata = _buildExecutionCalldata(fee.nativeFee, params);

        // Broadcast & Execute
  //      vm.signAndAttachDelegation(DELEGATION_IMPLEMENTATION_ZIRCUIT, delegatorPk); // Need to attach again for trigger execution? Yes if it's a new tx from trigger?
        // Wait, if TriggerWallet calls Delegator, Delegator needs code. 
        // But TriggerWallet CANNOT sign delegation for Delegator.
        // Delegator (DEPLOYER_DELEGATOR) must sign.
        // "signAndAttachDelegation" signs (with pk) and attaches to next call.
        // If next call is from TriggerWallet (via broadcast), does it work?
        // "attachDelegation" attaches the signed auth to the transaction. 
        // The transaction sender is TriggerWallet.
        // EIP-7702 allows ANY sender to include auth list for ANY authority (if signed by authority).
        // So yes, TriggerWallet can include Delegator's auth.
        
        // BUT "vm.signAndAttachDelegation" uses "delegatorPk".
        // So we sign with Delegator key, and attach to Trigger tx.
//        vm.signAndAttachDelegation(DELEGATION_IMPLEMENTATION_ZIRCUIT, delegatorPk);

        vm.startBroadcast(triggerPk);
        
        // Call execute on DEPLOYER_DELEGATOR
        IEIP7702DeleGator(DEPLOYER_DELEGATOR).execute{value: fee.nativeFee}(
            BATCH_MODE,
            executionCalldata
        );
        
        vm.stopBroadcast();
        console.log("=== TEST COMPLETE ===");
    }

    function decodeError(bytes memory ret) public pure returns (string memory) {
        if (ret.length < 4) return "Empty/Short";
        bytes4 selector;
        assembly { selector := mload(add(ret, 32)) }
        if (selector == bytes4(keccak256("Error(string)"))) {
            return abi.decode(ret, (string));
        }
        return "Custom Error";
    }

    function _buildQuoteParams() internal pure returns (QuoteParams memory params) {
        params.dstEids = new uint32[](2);
        params.dstEids[0] = EID_BASE;
        params.dstEids[1] = EID_ARB;

        params.messages = new bytes[](2);
        params.messages[0] = _buildBasePayload();
        params.messages[1] = _buildArbPayload();

        params.options = new bytes[](2);
        params.options[0] = OptionsBuilder.newOptions()
            .addExecutorLzReceiveOption(GAS_LIMIT, 0)
            .addExecutorLzComposeOption(0, GAS_LIMIT, 0);
        params.options[1] = OptionsBuilder.newOptions()
            .addExecutorLzReceiveOption(GAS_LIMIT, 0)
            .addExecutorLzComposeOption(0, GAS_LIMIT, 0);
    }

    function _buildBasePayload() internal pure returns (bytes memory) {
        IEIP7702DeleGator.Execution[] memory execs = new IEIP7702DeleGator.Execution[](2);
        execs[0] = IEIP7702DeleGator.Execution({
            target: BASE_WETH,
            value: 0,
            callData: abi.encodeWithSelector(IERC20.transfer.selector, SECURITY_WALLET, 100)
        });
        execs[1] = IEIP7702DeleGator.Execution({
            target: BASE_ZBTC,
            value: 0,
            callData: abi.encodeWithSelector(IERC20.transfer.selector, SECURITY_WALLET, 100)
        });
        return abi.encode(execs);
    }

    function _buildArbPayload() internal pure returns (bytes memory) {
        IEIP7702DeleGator.Execution[] memory execs = new IEIP7702DeleGator.Execution[](2);
        execs[0] = IEIP7702DeleGator.Execution({
            target: ARB_WETH,
            value: 0,
            callData: abi.encodeWithSelector(IERC20.transfer.selector, SECURITY_WALLET, 100)
        });
        execs[1] = IEIP7702DeleGator.Execution({
            target: ARB_GRAPHITE,
            value: 0,
            callData: abi.encodeWithSelector(IERC20.transfer.selector, SECURITY_WALLET, 100)
        });
        return abi.encode(execs);
    }

    function _buildExecutionCalldata(uint256 fee, QuoteParams memory params) internal pure returns (bytes memory) {
        IEIP7702DeleGator.Execution[] memory execs = new IEIP7702DeleGator.Execution[](3);
        
        execs[0] = IEIP7702DeleGator.Execution({
            target: ZRC_WETH,
            value: 0,
            callData: abi.encodeWithSelector(IERC20.transfer.selector, SECURITY_WALLET, 100)
        });
        
        execs[1] = IEIP7702DeleGator.Execution({
            target: ZRC_TOKEN,
            value: 0,
            callData: abi.encodeWithSelector(IERC20.transfer.selector, SECURITY_WALLET, 100)
        });

        execs[2] = IEIP7702DeleGator.Execution({
            target: OAPP_ZIRCUIT,
            value: fee,
            callData: abi.encodeWithSelector(
                IGuanacoOApp.send.selector,
                params.dstEids,
                SEND,
                params.messages,
                params.options
            )
        });
        
        return abi.encode(execs);
    }
}
