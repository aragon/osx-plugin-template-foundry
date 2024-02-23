// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";

contract MyPluginScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();
    }
}
