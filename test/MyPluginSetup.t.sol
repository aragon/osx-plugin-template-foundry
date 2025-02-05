// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MyPluginSetup} from "../src/setup/MyPluginSetup.sol";
import {MyPlugin} from "../src/MyPlugin.sol";
import {DAO} from "@aragon/osx/src/core/dao/DAO.sol";
import {DaoBuilder} from "./util/DaoBuilder.sol";
import {AragonTest} from "./util/AragonTest.sol";
import {PermissionLib} from "@aragon/osx-commons-contracts/src/permission/PermissionLib.sol";
import {IPluginSetup} from "@aragon/osx-commons-contracts/src/plugin/setup/IPluginSetup.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MyPluginSetupTest is AragonTest {
    MyPluginSetup pluginSetup;
    DAO dao;
    DaoBuilder builder;
    MyPlugin myPlugin;
    IERC20 lockableToken;
    IERC20 underlyingToken;

    function setUp() public virtual {
        vm.startPrank(alice);
        vm.warp(10 days);
        vm.roll(100);

        builder = new DaoBuilder();
        // Build the DAO using DaoBuilder
        (dao, myPlugin, lockableToken, underlyingToken) = builder
            .withTokenHolder(alice, 1 ether)
            .withTokenHolder(bob, 10 ether)
            .build();

        // Deploy the plugin setup
        pluginSetup = new MyPluginSetup();

        vm.stopPrank();
    }

    function test_WhenDeployingANewInstance() external view {
        // Verify the implementation address is set correctly
        address impl = pluginSetup.implementation();
        assertTrue(impl != address(0), "Implementation address should not be zero");
        assertTrue(impl.code.length > 0, "Implementation should be a contract");
    }

    function test_WhenPreparingAnInstallation() external {
        // Prepare installation parameters
        uint256 initialNumber = 42;
        bytes memory installParameters = abi.encode(initialNumber);

        // Call prepareInstallation
        (address plugin, IPluginSetup.PreparedSetupData memory preparedSetupData) = pluginSetup.prepareInstallation(
            address(dao),
            installParameters
        );

        // Verify the plugin was deployed
        assertTrue(plugin != address(0), "Plugin address should not be zero");
        assertTrue(plugin.code.length > 0, "Plugin should be a contract");

        // Verify the plugin was initialized correctly
        MyPlugin pluginInstance = MyPlugin(plugin);
        assertEq(pluginInstance.number(), initialNumber, "Plugin should be initialized with correct number");
        assertEq(address(pluginInstance.dao()), address(dao), "Plugin should be initialized with correct DAO");

        // Verify setup data
        assertEq(preparedSetupData.helpers.length, 0, "Should not have any helpers");
        assertEq(preparedSetupData.permissions.length, 0, "Should not have any permissions");
    }

    function test_WhenPreparingAnUninstallation() external {
        // First prepare an installation to get a plugin instance
        uint256 initialNumber = 42;
        bytes memory installParameters = abi.encode(initialNumber);
        (address plugin, ) = pluginSetup.prepareInstallation(address(dao), installParameters);

        // Prepare uninstallation
        IPluginSetup.SetupPayload memory payload = IPluginSetup.SetupPayload({
            plugin: plugin,
            currentHelpers: new address[](0),
            data: ""
        });

        // Call prepareUninstallation
        PermissionLib.MultiTargetPermission[] memory permissions = pluginSetup.prepareUninstallation(
            address(dao),
            payload
        );

        // Verify permissions
        assertEq(permissions.length, 0, "Should not have any permissions to remove");
    }

    function test_RevertWhen_PassingInvalidInstallParameters() external {
        // Create invalid parameters - empty bytes which can't be decoded as uint256
        bytes memory invalidParameters = new bytes(0);

        vm.expectRevert(); // Should revert when trying to decode invalid parameters
        pluginSetup.prepareInstallation(address(dao), invalidParameters);
    }
}
