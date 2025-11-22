// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { OApp, Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SimpleReceiver - A simple OApp receiver that sets a flag when receiving messages
 * @dev This contract demonstrates a minimal receiver that just sets a boolean flag
 *      when it receives a cross-chain message via LayerZero.
 */
contract SimpleReceiver is OApp, OAppOptionsType3 {
    /// @notice Flag that indicates a message has been received
    bool public messageReceived = false;
    
    /// @notice The last message that was received
    string public lastMessage;
    
    /// @notice The source endpoint ID of the last received message
    uint32 public lastSrcEid;
    
    /// @notice Emitted when a message is received
    event MessageReceived(string message, uint32 srcEid, bytes32 sender);

    /**
     * @dev Constructs a new SimpleReceiver contract instance.
     * @param _endpoint The LayerZero endpoint for this contract to interact with.
     * @param _owner The owner address that will be set as the owner of the contract.
     */
    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) Ownable(_owner) {}

    /**
     * @notice Internal function to handle receiving messages from another chain.
     * @dev Decodes the received message and sets the flag to true.
     * @param _origin Data about the origin of the received message.
     * @param message The received message content.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*guid*/,
        bytes calldata message,
        address, // Executor address as specified by the OApp.
        bytes calldata // Any extra data or options to trigger on receipt.
    ) internal override {
        // Decode the message (expecting a string)
        string memory _data = abi.decode(message, (string));
        
        // Set the flag
        messageReceived = true;
        lastMessage = _data;
        lastSrcEid = _origin.srcEid;
        
        emit MessageReceived(_data, _origin.srcEid, _origin.sender);
    }
}

