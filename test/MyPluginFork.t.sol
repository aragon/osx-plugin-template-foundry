// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {DaoUnauthorized} from "@aragon/osx/core/utils/auth.sol";
import {PluginRepo} from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";

import {AragonForkTest} from "./base/AragonForkTest.sol";
import {MyPluginSetup} from "../src/MyPluginSetup.sol";
import {MyPlugin} from "../src/MyPlugin.sol";
import {NON_EMPTY_BYTES} from "./constants.sol";

contract MyPluginFork is AragonForkTest {
    DAO internal dao;
    MyPlugin internal plugin;
    PluginRepo internal repo;
    MyPluginSetup internal setup;
    uint256 internal constant NUMBER = 420;
    address internal unauthorised = vm.addr(12345678);

    function setUp() public virtual override {
        super.setUp();
        setup = new MyPluginSetup();
        address _plugin;

        (dao, repo, _plugin) = deployDaoRepoPlugin(
            "simplestorage4202934800",
            address(setup),
            abi.encode(NUMBER)
        );

        plugin = MyPlugin(_plugin);
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
