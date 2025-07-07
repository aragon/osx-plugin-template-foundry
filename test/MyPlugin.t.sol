// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {TestBase} from "./lib/TestBase.sol";

import {SimpleBuilder} from "./builders/SimpleBuilder.sol";
import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {DaoUnauthorized} from "@aragon/osx-commons-contracts/src/permission/auth/auth.sol";
import {MyUpgradeablePlugin} from "../src/MyUpgradeablePlugin.sol";

contract MyPluginTest is TestBase {
    DAO dao;
    MyUpgradeablePlugin plugin;

    function setUp() public {
        // Customize the Builder to feature more default values and overrides
        (dao, plugin) = new SimpleBuilder().withInitialNumber(123).build();
    }

    modifier givenThePluginIsAlreadyInitialized() {
        _;
    }

    function test_RevertWhen_CallingInitialize() external givenThePluginIsAlreadyInitialized {
        // It Should revert
        vm.expectRevert("Initializable: contract is already initialized");
        plugin.initialize(dao, 69);
    }

    function test_WhenCallingDaoAndNumber() external view givenThePluginIsAlreadyInitialized {
        // It Should return the right values
        assertEq(address(plugin.dao()), address(dao));
        assertEq(plugin.number(), 123);
    }

    modifier givenTheCallerHasNoPermission() {
        address[] memory managers = new address[](2);
        managers[0] = alice;
        managers[1] = bob;

        (dao, plugin) = new SimpleBuilder().withDaoOwner(alice).withManagers(managers).build();

        _;
    }

    function test_RevertWhen_CallingSetNumber() external givenTheCallerHasNoPermission {
        // It Should revert

        // error DaoUnauthorized({dao: address(_dao),  where: _where,  who: _who,permissionId: _permissionId });
        vm.prank(carol);
        vm.expectRevert(
            abi.encodeWithSelector(DaoUnauthorized.selector, dao, plugin, carol, keccak256("MANAGER_PERMISSION"))
        );
        plugin.setNumber(0);
        assertEq(plugin.number(), 1);

        vm.prank(david);
        vm.expectRevert(
            abi.encodeWithSelector(DaoUnauthorized.selector, dao, plugin, david, keccak256("MANAGER_PERMISSION"))
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

    modifier givenTheCallerHasPermission() {
        address[] memory managers = new address[](2);
        managers[0] = alice;
        managers[1] = bob;

        (dao, plugin) = new SimpleBuilder().withInitialNumber(100).withManagers(managers).build();

        _;
    }

    function test_WhenCallingSetNumber2() external givenTheCallerHasPermission {
        // It should update the stored number

        vm.prank(alice);
        plugin.setNumber(69);

        vm.prank(bob);
        plugin.setNumber(123);
    }

    function test_WhenCallingNumber() external {
        // It Should return the right value
        (, plugin) = new SimpleBuilder().build();
        assertEq(plugin.number(), 1);

        plugin.setNumber(69);
        assertEq(plugin.number(), 69);

        plugin.setNumber(123);
        assertEq(plugin.number(), 123);

        plugin.setNumber(0x1133557799);
        assertEq(plugin.number(), 0x1133557799);
    }
}
