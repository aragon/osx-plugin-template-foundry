// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {PluginSetup, IPluginSetup} from "@aragon/osx-commons-contracts/src/plugin/setup/PluginSetup.sol";
import {DAO} from "@aragon/osx/src/core/dao/DAO.sol";
import {ALICE_ADDRESS, BOB_ADDRESS, CAROL_ADDRESS, DAVID_ADDRESS} from "../constants.sol";
import {Test} from "forge-std/Test.sol";

contract AragonTest is Test {
    address immutable alice = ALICE_ADDRESS;
    address immutable bob = BOB_ADDRESS;
    address immutable carol = CAROL_ADDRESS;
    address immutable david = DAVID_ADDRESS;
    address immutable randomWallet = vm.addr(1234567890);

    address immutable DAO_BASE = address(new DAO());

    bytes internal constant EMPTY_BYTES = "";

    constructor() {
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(carol, "Carol");
        vm.label(david, "David");
        vm.label(randomWallet, "Random wallet");
    }

    /// @notice Returns the address and private key associated to the given name.
    /// @param name The name to get the address and private key for.
    /// @return addr The address associated with the name.
    /// @return pk The private key associated with the name.
    function getWallet(string memory name) internal returns (address addr, uint256 pk) {
        pk = uint256(keccak256(abi.encodePacked(name)));
        addr = vm.addr(pk);
        vm.label(addr, name);
    }
}
