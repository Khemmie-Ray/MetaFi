// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {HoleskyStaker} from "../src/ReceiverOnHolseky.sol";

contract ReceiverOnHolsekyScript is Script {
    HoleskyStaker holeskyStaker;

    function run() public {
        vm.startBroadcast();
        // holeskyStaker = new HoleskyStaker();
        vm.stopBroadcast();
    }
}
