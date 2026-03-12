// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {ALICE_ADDRESS, BOB_ADDRESS, CAROL_ADDRESS, DAVID_ADDRESS} from "../constants.sol";
import {Test} from "forge-std/Test.sol";

contract TestBase is Test {
    // Convenience actors for testing
    address immutable ALICE = ALICE_ADDRESS;
    address immutable BOB = BOB_ADDRESS;
    address immutable CAROL = CAROL_ADDRESS;
    address immutable DAVID = DAVID_ADDRESS;
    address immutable RANDOM_ADDRESS = vm.addr(1234567890);

    constructor() {
        vm.label(ALICE, "Alice");
        vm.label(BOB, "Bob");
        vm.label(CAROL, "Carol");
        vm.label(DAVID, "David");
        vm.label(RANDOM_ADDRESS, "Random wallet");
    }

    /// @notice Returns the address and private key associated to the given name.
    /// @param name The name to get the address and private key for.
    /// @return addr The address associated with the name.
    /// @return pk The private key associated with the name.
    function makeWallet(string memory name) internal returns (address addr, uint256 pk) {
        pk = uint256(keccak256(abi.encodePacked(name)));
        addr = vm.addr(pk);
        vm.label(addr, name);
    }
}
