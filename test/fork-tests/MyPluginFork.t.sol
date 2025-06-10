// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {ForkTestBase} from "../lib/ForkTestBase.sol";

import {ForkBuilder} from "../builders/ForkBuilder.sol";
import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {DaoUnauthorized} from "@aragon/osx-commons-contracts/src/permission/auth/auth.sol";
import {PluginRepo} from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";

import {MyPluginSetup} from "../../src/setup/MyPluginSetup.sol";
import {MyUpgradeablePlugin} from "../../src/MyUpgradeablePlugin.sol";
import {NON_EMPTY_BYTES} from "../constants.sol";

contract MyPluginForkTest is ForkTestBase {
    DAO internal dao;
    MyUpgradeablePlugin internal plugin;
    PluginRepo internal repo;
    MyPluginSetup internal setup;

    function setUp() public virtual override {
        super.setUp();
        setup = new MyPluginSetup();

        (dao, repo, setup, plugin) = new ForkBuilder().build();
    }

    function test_endToEndFlow1() public {
        // Check the Repo
        PluginRepo.Version memory version = repo.getLatestVersion(repo.latestRelease());
        assertEq(version.pluginSetup, address(setup));
        assertEq(version.buildMetadata, NON_EMPTY_BYTES);

        // Check the DAO
        assertEq(keccak256(bytes(dao.daoURI())), keccak256(bytes("http://host/")));

        // Check the plugin initialization
        assertEq(plugin.number(), 1);

        // Store a new number
        vm.prank(bob);
        plugin.setNumber(69);
        assertEq(plugin.number(), 69);

        // Check that Carol cannot set number
        vm.expectRevert(
            abi.encodeWithSelector(DaoUnauthorized.selector, dao, plugin, carol, plugin.MANAGER_PERMISSION_ID())
        );
        vm.prank(carol);
        plugin.setNumber(100);

        assertEq(plugin.number(), 69);
    }

    function test_endToEndFlow2() public {
        (dao, repo, setup, plugin) = new ForkBuilder().withManager(david).withInitialNumber(200).build();

        // Check the Repo
        PluginRepo.Version memory version = repo.getLatestVersion(repo.latestRelease());
        assertEq(version.pluginSetup, address(setup));
        assertEq(version.buildMetadata, NON_EMPTY_BYTES);

        // Check the DAO
        assertEq(keccak256(bytes(dao.daoURI())), keccak256(bytes("http://host/")));

        // Check the plugin initialization
        assertEq(plugin.number(), 200);

        // Store a new number
        vm.prank(david);
        plugin.setNumber(69);
        assertEq(plugin.number(), 69);

        // Check that Carol cannot store a number
        vm.expectRevert(
            abi.encodeWithSelector(DaoUnauthorized.selector, dao, plugin, carol, plugin.MANAGER_PERMISSION_ID())
        );
        vm.prank(carol);
        plugin.setNumber(50);
        assertEq(plugin.number(), 69);
    }
}
