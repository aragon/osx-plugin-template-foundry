// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {ForkTestBase} from "./base/ForkTestBase.sol";

import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {DaoUnauthorized} from "@aragon/osx-commons-contracts/src/permission/auth/auth.sol";
import {PluginRepo} from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";

import {MyUpgradeablePluginSetup} from "../src/MyUpgradeablePluginSetup.sol";
import {MyUpgradeablePlugin} from "../src/MyUpgradeablePlugin.sol";
import {NON_EMPTY_BYTES} from "./constants.sol";

contract ForkTests is ForkTestBase {
    DAO internal dao;
    MyUpgradeablePlugin internal plugin;
    PluginRepo internal repo;
    MyUpgradeablePluginSetup internal setup;
    uint256 internal constant NUMBER = 420;
    address internal unauthorised = vm.addr(12345678);

    function setUp() public virtual override {
        super.setUp();
        setup = new MyUpgradeablePluginSetup();
        address _plugin;

        (dao, repo, _plugin) = deployDaoRepoPlugin(
            "set-number-test-plugin-1234",
            address(setup),
            abi.encode(NUMBER)
        );

        plugin = MyUpgradeablePlugin(_plugin);
    }

    function test_e2e() public {
        // test repo
        PluginRepo.Version memory version = repo.getLatestVersion(
            repo.latestRelease()
        );
        assertEq(version.pluginSetup, address(setup));
        assertEq(version.buildMetadata, NON_EMPTY_BYTES);

        // test dao
        assertEq(
            keccak256(bytes(dao.daoURI())),
            keccak256(bytes("http://host/"))
        );

        // test plugin init correctly
        assertEq(plugin.number(), 420);

        // test dao store number
        vm.prank(address(dao));
        plugin.storeNumber(69);

        // test unauthorised cannot store number
        vm.prank(unauthorised);
        vm.expectRevert(
            abi.encodeWithSelector(
                DaoUnauthorized.selector,
                dao,
                plugin,
                unauthorised,
                keccak256("STORE_PERMISSION")
            )
        );
        plugin.storeNumber(69);
    }
}
