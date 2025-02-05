// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {IDAO} from "@aragon/osx-commons-contracts/src/dao/IDAO.sol";
import {DAO} from "@aragon/osx/src/core/dao/DAO.sol";
import {MyPlugin} from "../src/MyPlugin.sol";
import {DaoBuilder} from "./util/DaoBuilder.sol";
import {AragonTest} from "./util/AragonTest.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import {createProxyAndCall} from "../src/util/proxy.sol";

contract MyPluginTest is AragonTest {
    using SafeCastUpgradeable for uint256;

    DaoBuilder builder;
    DAO dao;
    MyPlugin myPlugin;
    IERC20 lockableToken;
    IERC20 underlyingToken;
    uint256 proposalId; // Not used in this test

    function setUp() public virtual {
        vm.startPrank(alice);
        vm.warp(10 days);
        vm.roll(100);

        builder = new DaoBuilder();
        // Build the DAO using DaoBuilder; we ignore the plugin returned since we test MyPlugin separately.
        (dao, , lockableToken, underlyingToken) = builder
            .withTokenHolder(alice, 1 ether)
            .withTokenHolder(bob, 10 ether)
            .withTokenHolder(carol, 10 ether)
            .withTokenHolder(david, 15 ether)
            .build();

        // Deploy MyPlugin through a proxy and initialize it
        address myPluginBase = address(new MyPlugin());
        myPlugin = MyPlugin(
            createProxyAndCall(myPluginBase, abi.encodeCall(MyPlugin.initialize, (IDAO(address(dao)), 42)))
        );

        // Grant STORE_PERMISSION_ID to alice
        dao.grant(address(myPlugin), alice, myPlugin.STORE_PERMISSION_ID());

        vm.stopPrank();
    }

    function testStoreNumber() public {
        vm.startPrank(alice);
        assertEq(myPlugin.number(), 42, "Initial number is incorrect");
        myPlugin.storeNumber(100);
        assertEq(myPlugin.number(), 100, "Stored number did not update");
        vm.stopPrank();
    }
}
