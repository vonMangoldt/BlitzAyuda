// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CallDataVerifyer} from "../src/CallDataVerifyer.sol";

contract CallDataVerifyerTest is Test {
    CallDataVerifyer public callDataVerifyer;

    function setUp() public {
        callDataVerifyer = new CallDataVerifyer();
    }

    function test_SelectorIdentifyer()
        public
        view
    {
        bytes memory callData = callDataVerifyer.createTransferCallData(
            address(0x1234567890123456789012345678901234567890),
            1000000000000000000
        );

        assertEq(callDataVerifyer.verifyCallData(callData), true);
    }

    function test_SelectorIdentifyer_Fake()
        public
        view
    {
        bytes memory callData = callDataVerifyer.createFakeTransferCallData(
            address(0x1234567890123456789012345678901234567890),
            1000000000000000000
        );

        assertEq(
            callDataVerifyer.verifyCallData(callData),
            false
        );
    }
}
