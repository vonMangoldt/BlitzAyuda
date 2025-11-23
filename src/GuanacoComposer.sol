// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { ILayerZeroComposer } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroComposer.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

interface IGuanacoOApp {
    function getOriginalSender(bytes32 _guid) external view returns (address);
}

/**
 * @title SimpleReceiver - A simple OApp receiver that sets a flag when receiving messages
 * @dev This contract demonstrates a minimal receiver that just sets a boolean flag
 *      when it receives a cross-chain message via LayerZero.
 */
contract GuanacoComposer is ILayerZeroComposer {
    string public lastMessage;

    address public immutable OAPP;
    address public immutable ENDPOINT;

    /// @notice Emitted when a message is received
    event ComposeReceived(address sender, bytes32 guid);

    /**
     * @dev Constructs a new SimpleReceiver contract instance.
     * @param _oapp The OApp address for this contract to interact with.
     * @param _endpoint The LayerZero endpoint for this contract to interact with.
     */
    constructor(address _oapp, address _endpoint) {
        OAPP = _oapp;
        ENDPOINT = _endpoint;
    }

    /// @notice Handles incoming composed messages from LayerZero.
    /// @dev Decodes the message payload and updates the state.
    /// @param _oApp The address of the originating OApp.
    /// @param _guid The globally unique identifier of the message.
    /// @param _message The encoded message content.
    function lzCompose(
        address _oApp,
        bytes32 _guid,
        bytes calldata _message,
        address,
        bytes calldata
    ) external payable {
        // Perform checks to make sure composed message comes from correct OApp.
        require(_oApp == OAPP, "!oApp");
        require(msg.sender == ENDPOINT, "!endpoint");

        // Decode the payload to get the message
        (string memory message) = abi.decode(_message, (string));
        lastMessage = message;
        emit ComposeReceived(IGuanacoOApp(_oApp).getOriginalSender(_guid), _guid);
    }
}

