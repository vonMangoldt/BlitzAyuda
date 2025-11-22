// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CallDataVerifyer} from "../src/CallDataVerifyer.sol";

contract CallDataVerifyerTest is Test {
    CallDataVerifyer public callDataVerifyer;

    function setUp() public {
        callDataVerifyer = new CallDataVerifyer();
    }

    function test_Increment() public {
//        callDataVerifyer.verifyCallData(callData);
//        assertEq(callDataVerifyer.verifyCallData(callData), true);
    }

}
