// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {MetaFiHook} from "../src/MetaFiHook.sol";

contract MetaFIScript is Script {
    MetaFiHook public metaFiHook;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // metafi = new MetaFi();

        vm.stopBroadcast();
    }
}

//  forge install smartcontractkit/chainlink --no-commit
