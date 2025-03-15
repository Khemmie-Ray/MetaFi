// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MetaFi} from "../src/MetaFi.sol";

contract MetaFIScript is Script {
    MetaFi public metafi;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // metafi = new MetaFi();

        vm.stopBroadcast();
    }
}
