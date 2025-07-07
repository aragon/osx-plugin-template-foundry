// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

bytes32 constant EXECUTE_PERMISSION_ID = keccak256("EXECUTE_PERMISSION");
bytes32 constant ROOT_PERMISSION_ID = keccak256("ROOT_PERMISSION");

uint64 constant MAX_UINT64 = uint64(2 ** 64 - 1);
address constant ADDRESS_ZERO = address(0x0);
address constant NO_CONDITION = ADDRESS_ZERO;
bytes constant EMPTY_BYTES = "";
bytes constant NON_EMPTY_BYTES = " ";

// Actors
address constant ALICE_ADDRESS = address(0xa11ce00000000000a11ce00000000000a11ce);
address constant BOB_ADDRESS = address(0xB0B00000000B0B00000000B0B00000000B0B0);
address constant CAROL_ADDRESS = address(0xc460100000000000c460100000000000c4601);
address constant DAVID_ADDRESS = address(0xd471d00000000000d471d00000000000d471d);

address constant RANDOM_ADDRESS = address(0x0123456789012345678901234567890123456789);
