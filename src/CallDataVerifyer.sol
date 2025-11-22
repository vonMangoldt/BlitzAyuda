// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract CallDataVerifyer {

    function transfer(
        address to,
        uint256 amount
    )
        public
        pure
        returns (bool)
    {
        return true;
    }

    function verifyCallData(
        bytes memory callData
    )
        public
        pure
        returns (bool)
    {
        return true;
    }

    function _checkSelector(
        bytes memory _callData
    )
        internal
        pure
        returns (bytes4 selector)
    {
        assembly {
            selector := mload(add(_callData, 32))
        }
    }
}
