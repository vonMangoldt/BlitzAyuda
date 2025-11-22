// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {CallDataVerifyer} from "../src/CallDataVerifyer.sol";

contract CallDataVerifyerScript is Script {
    CallDataVerifyer public callDataVerifyer;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        callDataVerifyer = new CallDataVerifyer();

        vm.stopBroadcast();
    }
}
