// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { OApp, MessagingFee, Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GuanacoOApp
 * @notice Contract for emergency exit developed for EthGlobal Buenos Aires 2025
 */
contract GuanacoOApp is OApp, OAppOptionsType3 {
    mapping(bytes32 guid => Origin origin) public origins;
    address public composer;

    /// @notice Message types that are used to identify the various OApp operations.
    /// @dev These values are used in things like combineOptions() in OAppOptionsType3 (enforcedOptions).
    uint16 public constant SEND = 1;

    /// @notice Emitted when a message is sent to another chain (A -> B).
    event MessageSent(string message, uint32 dstEid);

    /// @notice Emitted when a message is received
    event MessageReceived(uint32 srcEid, address sender, bytes32 guid);

    /// @dev Revert with this error when an invalid message type is used.
    error InvalidMsgType();

    /**
     * @dev Constructs a new BatchSend contract instance.
     * @param _endpoint The LayerZero endpoint for this contract to interact with.
     * @param _owner The owner address that will be set as the owner of the contract.
     */
    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) Ownable(_owner) {}

    function _payNative(uint256 _nativeFee) internal override returns (uint256 nativeFee) {
        if (msg.value < _nativeFee) revert NotEnoughNative(msg.value);
        return _nativeFee;
    }

    /**
     * @notice Returns the estimated messaging fee for a given message.
     * @param _dstEids Destination endpoint ID array where the message will be batch sent.
     * @param _msgType The type of message being sent.
     * @param _messages The message contents, same ordre as _dstEids.
     * @param _extraSendOptions Extra gas options for receiving the send call (A -> B) per chain, same ordre as _dstEids.
     * Will be summed with enforcedOptions, even if no enforcedOptions are set.
     * @param _payInLzToken Boolean flag indicating whether to pay in LZ token.
     * @return totalFee The estimated messaging fee for sending to all pathways.
     */
    function quote(
        uint32[] memory _dstEids,
        uint16 _msgType,
        string[] memory _messages,
        bytes[] calldata _extraSendOptions,
        bool _payInLzToken
    ) public view returns (MessagingFee memory totalFee) {
        for (uint i = 0; i < _dstEids.length; i++) {
            bytes memory options = combineOptions(_dstEids[i], _msgType, _extraSendOptions[i]);
            bytes memory encodedMessage = abi.encode(_messages[i]);
            MessagingFee memory fee = _quote(_dstEids[i], encodedMessage, options, _payInLzToken);
            totalFee.nativeFee += fee.nativeFee;
            totalFee.lzTokenFee += fee.lzTokenFee;
        }
    }

    function send(
        uint32[] memory _dstEids,
        uint16 _msgType,
        string[] memory _messages,
        bytes[] calldata _extraSendOptions
    ) external payable {
        if (_msgType != SEND) {
            revert InvalidMsgType();
        }

        // Calculate the total messaging fee required.
        MessagingFee memory totalFee = quote(_dstEids, _msgType, _messages, _extraSendOptions, false);
        require(msg.value >= totalFee.nativeFee, "Insufficient fee provided");

        uint256 totalNativeFeeUsed = 0;
        uint256 remainingValue = msg.value;

        for (uint i = 0; i < _dstEids.length; i++) {
            bytes memory _encodedMessage = abi.encode(_messages[i]);
            bytes memory options = combineOptions(_dstEids[i], _msgType, _extraSendOptions[i]);
            MessagingFee memory fee = _quote(_dstEids[i], _encodedMessage, options, false);

            totalNativeFeeUsed += fee.nativeFee;
            remainingValue -= fee.nativeFee;

            // Ensure the current call has enough allocated fee from msg.value.
            require(remainingValue >= 0, "Insufficient fee for this destination");

            _lzSend(
                _dstEids[i],
                _encodedMessage,
                options,
                fee,
                payable(msg.sender)
            );

            emit MessageSent(_messages[i], _dstEids[i]);
        }
    }

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
        emit MessageReceived(_origin.srcEid, address(uint160(uint256(_origin.sender))), _guid);
    }

    /**
     * @notice Returns the original sender of a message on source chain.
     * @param _guid The globally unique identifier of the message.
     * @return The original sender of the message.
     */
    function getOriginalSender(bytes32 _guid) external view returns (address) {
        return address(uint160(uint256(origins[_guid].sender)));
    }

    /**
     * @notice Sets the composer address.
     * @param _composer The address of the composer.
     */
    function setComposer(address _composer) external onlyOwner {
        composer = _composer;
    }
}