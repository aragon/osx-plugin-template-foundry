// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {TestBase} from "../lib/TestBase.sol";

import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {MyUpgradeablePlugin} from "../../src/MyUpgradeablePlugin.sol";
import {MyPluginSetup} from "../../src/setup/MyPluginSetup.sol";
import {ProxyLib} from "@aragon/osx-commons-contracts/src/utils/deployment/ProxyLib.sol";

contract SimpleBuilder is TestBase {
    address immutable DAO_BASE = address(new DAO());
    address immutable UPGRADEABLE_PLUGIN_BASE = address(new MyUpgradeablePlugin());

    // Parameters to override
    address daoOwner; // Used for testing purposes only
    address[] managers; // daoOwner will be used if eventually empty
    uint256 initialNumber = 1;

    constructor() {
        // Set the caller as the initial daoOwner
        // It can grant and revoke permissions freely for testing purposes
        withDaoOwner(msg.sender);
    }

    // Override methods
    function withDaoOwner(address _newOwner) public returns (SimpleBuilder) {
        daoOwner = _newOwner;
        return this;
    }

    function withManagers(address[] memory _newManagers) public returns (SimpleBuilder) {
        for (uint256 i = 0; i < _newManagers.length; i++) {
            managers.push(_newManagers[i]);
        }
        return this;
    }

    function withInitialNumber(uint256 _number) public returns (SimpleBuilder) {
        initialNumber = _number;
        return this;
    }

    /// @dev Creates a DAO with the given orchestration settings.
    /// @dev The setup is done on block/timestamp 0 and tests should be made on block/timestamp 1 or later.
    function build() public returns (DAO dao, MyUpgradeablePlugin plugin) {
        // Deploy the DAO with `daoOwner` as ROOT
        dao = DAO(
            payable(
                ProxyLib.deployUUPSProxy(
                    address(DAO_BASE), abi.encodeCall(DAO.initialize, ("", daoOwner, address(0x0), ""))
                )
            )
        );

        // Plugin
        plugin = MyUpgradeablePlugin(
            ProxyLib.deployUUPSProxy(
                address(UPGRADEABLE_PLUGIN_BASE), abi.encodeCall(MyUpgradeablePlugin.initialize, (dao, initialNumber))
            )
        );

        vm.startPrank(daoOwner);

        // Grant plugin permissions
        if (managers.length > 0) {
            for (uint256 i = 0; i < managers.length; i++) {
                dao.grant(address(plugin), managers[i], plugin.MANAGER_PERMISSION_ID());
            }
        } else {
            // Set the daoOwner as the plugin manager if no managers are defined
            dao.grant(address(plugin), daoOwner, plugin.MANAGER_PERMISSION_ID());
        }

        vm.stopPrank();

        // Labels
        vm.label(address(dao), "DAO");
        vm.label(address(plugin), "MyUpgradeablePlugin");

        // Moving forward to avoid collisions
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
    }
}
