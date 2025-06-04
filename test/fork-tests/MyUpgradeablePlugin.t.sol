// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {ForkTestBase} from "../lib/ForkTestBase.sol";

import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {DaoUnauthorized} from "@aragon/osx-commons-contracts/src/permission/auth/auth.sol";
import {PluginRepo} from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";

import {MyUpgradeablePluginSetup} from "../../src/setup/MyUpgradeablePluginSetup.sol";
import {MyUpgradeablePlugin} from "../../src/MyUpgradeablePlugin.sol";
import {NON_EMPTY_BYTES} from "../constants.sol";

contract MyUpgradeablePluginTest is ForkTestBase {
    DAO internal dao;
    MyUpgradeablePlugin internal plugin;
    PluginRepo internal repo;
    MyUpgradeablePluginSetup internal setup;
    uint256 internal constant NUMBER = 420;

    function setUp() public virtual override {
        super.setUp();
        setup = new MyUpgradeablePluginSetup();
        address _plugin;

        (dao, repo, _plugin) = deployDaoRepoPlugin(
            "set-number-test-plugin-1234",
            address(setup),
            setup.encodeInstallationParams(alice, NUMBER)
        );

        plugin = MyUpgradeablePlugin(_plugin);
    }

    function test_endToEndFlow() public {
        // Check the Repo
        PluginRepo.Version memory version = repo.getLatestVersion(
            repo.latestRelease()
        );
        assertEq(version.pluginSetup, address(setup));
        assertEq(version.buildMetadata, NON_EMPTY_BYTES);

        // Check the DAO
        assertEq(
            keccak256(bytes(dao.daoURI())),
            keccak256(bytes("http://host/"))
        );

        // Check the plugin initialization
        assertEq(plugin.number(), 420);

        // Store a new number
        vm.prank(alice);
        plugin.setNumber(69);

        // Check that Bob cannot set  number
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                DaoUnauthorized.selector,
                dao,
                plugin,
                bob,
                plugin.STORE_PERMISSION_ID()
            )
        );
        plugin.setNumber(69);
    }
}
