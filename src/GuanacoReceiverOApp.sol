// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { OApp, Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GuanacoReceiverOApp
 */
contract GuanacoReceiverOApp is OApp, OAppOptionsType3 {
    mapping(bytes32 guid => Origin origin) public origins;
    address public composer;

    /// @notice Emitted when a message is received
    event MessageReceived(uint32 srcEid, address sender, bytes32 guid);

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
        bytes32 _guid,
        bytes calldata message,
        address, // Executor address as specified by the OApp.
        bytes calldata // Any extra data or options to trigger on receipt.
    ) internal override {
        origins[_guid] = _origin;
        endpoint.sendCompose(composer, _guid, 0, message);
        emit MessageReceived(_origin.srcEid, address(_origin.sender), _guid);
    }

    function getOriginalSender(bytes32 _guid) external view returns (address) {
        return origins[_guid].sender;
    }

    function setComposer(address _composer) external onlyOwner {
        composer = _composer;
    }
}
