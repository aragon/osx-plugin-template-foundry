// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

function createProxyAndCall(address logic, bytes memory data) returns (address) {
    return address(new ERC1967Proxy(logic, data));
}

function createSaltedProxyAndCall(address logic, bytes memory data, bytes32 salt) returns (address) {
    return address(new ERC1967Proxy{salt: salt}(logic, data));
}

function predictProxyAddress(address factory, bytes32 salt, address logic, bytes memory data)
    pure
    returns (address predictedAddress)
{
    predictedAddress = address(
        uint160(
            uint256(
                keccak256(
                    abi.encodePacked(
                        bytes1(0xff),
                        factory,
                        salt,
                        keccak256(abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(logic, data)))
                    )
                )
            )
        )
    );
}
