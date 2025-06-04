// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {TestBase} from "./lib/TestBase.sol";

import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {DaoUnauthorized} from "@aragon/osx-commons-contracts/src/permission/auth/auth.sol";
import {MyUpgradeablePluginSetup} from "../src/setup/MyUpgradeablePluginSetup.sol";
import {MyUpgradeablePlugin} from "../src/MyUpgradeablePlugin.sol";

abstract contract MyUpgradeablePluginTest is TestBase {
    DAO internal dao;
    MyUpgradeablePlugin internal plugin;
    MyUpgradeablePluginSetup internal setup;
    uint256 internal constant NUMBER = 420;

    function setUp() public virtual {
        setup = new MyUpgradeablePluginSetup();
        bytes memory setupData = abi.encode(NUMBER);

        (DAO _dao, address _plugin) = deployDaoRepoPlugin(
            "set-number-test-plugin-5555",
            setup,
            setupData
        );

        dao = _dao;
        plugin = MyUpgradeablePlugin(_plugin);
    }
}

contract MyUpgradeablePluginInitializeTest is MyUpgradeablePluginTest {
    function setUp() public override {
        super.setUp();
    }

    function test_initialize() public {
        assertEq(address(plugin.dao()), address(dao));
        assertEq(plugin.number(), NUMBER);
    }

    function test_reverts_if_reinitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        plugin.initialize(dao, 69);
    }
}

contract MyUpgradeablePluginStoreNumberTest is MyUpgradeablePluginTest {
    function setUp() public override {
        super.setUp();
    }

    function test_store_number() public {
        vm.prank(address(dao));
        plugin.storeNumber(69);
        assertEq(plugin.number(), 69);
    }

    function test_reverts_if_not_auth() public {
        // error DaoUnauthorized({dao: address(_dao),  where: _where,  who: _who,permissionId: _permissionId });
        vm.expectRevert(
            abi.encodeWithSelector(
                DaoUnauthorized.selector,
                dao,
                plugin,
                address(this),
                keccak256("STORE_PERMISSION")
            )
        );
        plugin.storeNumber(69);
    }
}
