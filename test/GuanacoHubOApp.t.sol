// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

// Contract imports
import { GuanacoHubOApp, MessagingFee } from "../src/GuanacoHubOApp.sol";
import { SimpleReceiver } from "../src/SimpleReceiver.sol";

// OApp imports
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

// Forge imports
import "forge-std/console.sol";

// DevTools imports
import { TestHelperOz5 } from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

/**
 * @title GuanacoHubOAppTest
 * @notice Test suite for batch sending functionality of GuanacoHubOApp
 */
contract GuanacoHubOAppTest is TestHelperOz5 {
    using OptionsBuilder for bytes;

    // Endpoint IDs for three chains
    uint32 private constant CHAIN_A_EID = 1; // Sender chain
    uint32 private constant CHAIN_B_EID = 2; // Receiver chain 1
    uint32 private constant CHAIN_C_EID = 3; // Receiver chain 2

    // Contracts
    GuanacoHubOApp private hubOApp; // Deployed on chain A
    SimpleReceiver private receiverB; // Deployed on chain B
    SimpleReceiver private receiverC; // Deployed on chain C

    // Test user
    address private user = address(0x1);

    function setUp() public virtual override {
        vm.deal(user, 1000 ether);

        super.setUp();
        // Set up 3 endpoints (chains)
        setUpEndpoints(3, LibraryType.UltraLightNode);

        // Deploy GuanacoHubOApp on chain A (sender)
        hubOApp = GuanacoHubOApp(
            _deployOApp(
                type(GuanacoHubOApp).creationCode,
                abi.encode(address(endpoints[CHAIN_A_EID]), address(this))
            )
        );

        // Deploy SimpleReceiver on chain B
        receiverB = SimpleReceiver(
            _deployOApp(
                type(SimpleReceiver).creationCode,
                abi.encode(address(endpoints[CHAIN_B_EID]), address(this))
            )
        );

        // Deploy SimpleReceiver on chain C
        receiverC = SimpleReceiver(
            _deployOApp(
                type(SimpleReceiver).creationCode,
                abi.encode(address(endpoints[CHAIN_C_EID]), address(this))
            )
        );

        // Wire all OApps together
        address[] memory oapps = new address[](3);
        oapps[0] = address(hubOApp);
        oapps[1] = address(receiverB);
        oapps[2] = address(receiverC);
        this.wireOApps(oapps);
    }

    function test_constructor() public {
        assertEq(hubOApp.owner(), address(this));
        assertEq(receiverB.owner(), address(this));
        assertEq(receiverC.owner(), address(this));

        assertEq(address(hubOApp.endpoint()), address(endpoints[CHAIN_A_EID]));
        assertEq(address(receiverB.endpoint()), address(endpoints[CHAIN_B_EID]));
        assertEq(address(receiverC.endpoint()), address(endpoints[CHAIN_C_EID]));
    }

    /**
     * @notice Test batch sending from chain A to both chain B and chain C
     * @dev Verifies that both receivers receive their messages and flags are set
     */
    function test_batchSend() public {
        // Prepare messages for batch send
        uint32[] memory dstEids = new uint32[](2);
        dstEids[0] = CHAIN_B_EID;
        dstEids[1] = CHAIN_C_EID;

        string[] memory messages = new string[](2);
        messages[0] = "Hello from Chain A to Chain B!";
        messages[1] = "Hello from Chain A to Chain C!";

        // Build options with executor gas
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);

        // Get quote for batch send
        MessagingFee memory totalFee = hubOApp.quote(
            dstEids,
            GuanacoHubOApp.SEND,
            messages,
            options,
            false
        );

        // Verify initial state - flags should be false
        assertEq(receiverB.messageReceived(), false, "Receiver B flag should be false initially");
        assertEq(receiverC.messageReceived(), false, "Receiver C flag should be false initially");
        assertEq(receiverB.lastMessage(), "", "Receiver B should have no message initially");
        assertEq(receiverC.lastMessage(), "", "Receiver C should have no message initially");

        // Execute batch send
        vm.prank(user);
        hubOApp.send{ value: totalFee.nativeFee }(dstEids, GuanacoHubOApp.SEND, messages, options);

        // Verify packets were sent to chain B
        verifyPackets(CHAIN_B_EID, addressToBytes32(address(receiverB)));

        // Verify packets were sent to chain C
        verifyPackets(CHAIN_C_EID, addressToBytes32(address(receiverC)));

        // Verify both receivers received their messages
        assertEq(receiverB.messageReceived(), true, "Receiver B flag should be set");
        assertEq(receiverC.messageReceived(), true, "Receiver C flag should be set");
        assertEq(receiverB.lastMessage(), messages[0], "Receiver B should have correct message");
        assertEq(receiverC.lastMessage(), messages[1], "Receiver C should have correct message");
        assertEq(receiverB.lastSrcEid(), CHAIN_A_EID, "Receiver B should have correct source EID");
        assertEq(receiverC.lastSrcEid(), CHAIN_A_EID, "Receiver C should have correct source EID");
    }

    /**
     * @notice Test batch send with different messages to verify correct routing
     */
    function test_batchSend_differentMessages() public {
        uint32[] memory dstEids = new uint32[](2);
        dstEids[0] = CHAIN_B_EID;
        dstEids[1] = CHAIN_C_EID;

        string[] memory messages = new string[](2);
        messages[0] = "Message for B";
        messages[1] = "Message for C";

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);

        MessagingFee memory totalFee = hubOApp.quote(
            dstEids,
            GuanacoHubOApp.SEND,
            messages,
            options,
            false
        );

        vm.prank(user);
        hubOApp.send{ value: totalFee.nativeFee }(dstEids, GuanacoHubOApp.SEND, messages, options);

        // Verify packets
        verifyPackets(CHAIN_B_EID, addressToBytes32(address(receiverB)));
        verifyPackets(CHAIN_C_EID, addressToBytes32(address(receiverC)));

        // Verify each receiver got the correct message
        assertEq(receiverB.lastMessage(), "Message for B", "Receiver B should get message for B");
        assertEq(receiverC.lastMessage(), "Message for C", "Receiver C should get message for C");
    }

    /**
     * @notice Test that batch send fails with insufficient fee
     */
    function test_batchSend_insufficientFee() public {
        uint32[] memory dstEids = new uint32[](2);
        dstEids[0] = CHAIN_B_EID;
        dstEids[1] = CHAIN_C_EID;

        string[] memory messages = new string[](2);
        messages[0] = "Hello B";
        messages[1] = "Hello C";

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);

        MessagingFee memory totalFee = hubOApp.quote(
            dstEids,
            GuanacoHubOApp.SEND,
            messages,
            options,
            false
        );

        // Try to send with insufficient fee
        vm.prank(user);
        vm.expectRevert("Insufficient fee provided");
        hubOApp.send{ value: totalFee.nativeFee - 1 }(dstEids, GuanacoHubOApp.SEND, messages, options);
    }
}

