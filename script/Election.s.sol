// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {Election} from "../src/Election.sol";

contract ElectionScript is Script {
    Election public election;
    function run() public {
        vm.startBroadcast();
        election = new Election();
        vm.stopBroadcast();
    }
}
