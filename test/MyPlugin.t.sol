// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {TestBase} from "./lib/TestBase.sol";

import {SimpleBuilder} from "./builders/SimpleBuilder.sol";
import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {DaoUnauthorized} from "@aragon/osx-commons-contracts/src/permission/auth/auth.sol";
import {MyPluginSetup} from "../src/setup/MyPluginSetup.sol";
import {MyUpgradeablePlugin} from "../src/MyUpgradeablePlugin.sol";

contract MyUpgradeablePluginInitializeTest is TestBase {
    DAO dao;
    MyUpgradeablePlugin plugin;

    function setUp() public {
        // Customize the Builder to feature more default values and overrides
        (dao, plugin) = new SimpleBuilder().withInitialNumber(123).build();
    }

    function test_initialize() public view {
        assertEq(address(plugin.dao()), address(dao));
        assertEq(plugin.number(), 123);
    }

    function test_reverts_if_reinitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        plugin.initialize(dao, 69);
    }
}

contract MyUpgradeablePluginStoreNumberTest is TestBase {
    DAO dao;
    MyUpgradeablePlugin plugin;

    function setUp() public {
        // Customize the Builder to feature more default values and overrides
        (dao, plugin) = new SimpleBuilder().withInitialNumber(123).build();
    }

    function test_store_number() public {
        address[] memory managers = new address[](2);
        managers[0] = alice;
        managers[1] = bob;

        (dao, plugin) = new SimpleBuilder()
            .withDaoOwner(david)
            .withInitialNumber(100)
            .withManagers(managers)
            .build();

        vm.prank(alice);
        plugin.setNumber(69);
        assertEq(plugin.number(), 69);

        vm.prank(bob);
        plugin.setNumber(123);
        assertEq(plugin.number(), 123);
    }

    function test_reverts_if_not_auth() public {
        (dao, plugin) = new SimpleBuilder().withDaoOwner(alice).build();

        // error DaoUnauthorized({dao: address(_dao),  where: _where,  who: _who,permissionId: _permissionId });
        vm.prank(carol);
        vm.expectRevert(
            abi.encodeWithSelector(
                DaoUnauthorized.selector,
                dao,
                plugin,
                carol,
                keccak256("MANAGER_PERMISSION")
            )
        );
        plugin.setNumber(0);
        assertEq(plugin.number(), 1);

        vm.prank(david);
        vm.expectRevert(
            abi.encodeWithSelector(
                DaoUnauthorized.selector,
                dao,
                plugin,
                david,
                keccak256("MANAGER_PERMISSION")
            )
        );
        plugin.setNumber(50);
        assertEq(plugin.number(), 1);

        // Grant the missing permission
        vm.startPrank(alice);
        dao.grant(address(plugin), david, plugin.MANAGER_PERMISSION_ID());
        vm.stopPrank();

        // OK
        vm.prank(david);
        plugin.setNumber(50);
        assertEq(plugin.number(), 50);
    }
}
