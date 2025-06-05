// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {ForkTestBase} from "../lib/ForkTestBase.sol";

import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {DAOFactory} from "@aragon/osx/framework/dao/DAOFactory.sol";
import {PluginRepoFactory} from "@aragon/osx/framework/plugin/repo/PluginRepoFactory.sol";
import {PluginRepo} from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";
import {PluginSetupRef} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessorHelpers.sol";
import {MyUpgradeablePlugin} from "../../src/MyUpgradeablePlugin.sol";
import {MyUpgradeablePluginSetup} from "../../src/setup/MyUpgradeablePluginSetup.sol";
import {NON_EMPTY_BYTES} from "../constants.sol";

contract ForkBuilder is ForkTestBase {
    address immutable DAO_BASE = address(new DAO());
    address immutable UPGRADEABLE_PLUGIN_BASE =
        address(new MyUpgradeablePlugin());

    // Add your own parameters here
    address daoOwner = alice; // Used for testing purposes only
    address manager = bob;
    uint256 initialNumber = 1;

    // Add your own builder overrides here
    function withDaoOwner(address _newOwner) public returns (ForkBuilder) {
        daoOwner = _newOwner;
        return this;
    }

    function withManager(address _manager) public returns (ForkBuilder) {
        manager = _manager;
        return this;
    }

    function withInitialNumber(uint256 _number) public returns (ForkBuilder) {
        initialNumber = _number;
        return this;
    }

    /// @dev Creates a DAO with the given orchestration settings.
    /// @dev The setup is done on block/timestamp 0 and tests should be made on block/timestamp 1 or later.
    function build()
        public
        returns (
            DAO dao,
            PluginRepo pluginRepo,
            MyUpgradeablePluginSetup pluginSetup,
            MyUpgradeablePlugin plugin
        )
    {
        // Prepare a plugin repo with an initial version and subdomain
        bytes memory pluginRepoSubdomain = abi.encodePacked(
            "my-upgradeable-plugin-",
            vm.toString(block.timestamp)
        );
        pluginSetup = new MyUpgradeablePluginSetup();
        pluginRepo = pluginRepoFactory.createPluginRepoWithFirstVersion({
            _subdomain: string(pluginRepoSubdomain),
            _pluginSetup: address(pluginSetup),
            _maintainer: address(this),
            _releaseMetadata: NON_EMPTY_BYTES,
            _buildMetadata: NON_EMPTY_BYTES
        });

        // DAO settings
        DAOFactory.DAOSettings memory daoSettings = DAOFactory.DAOSettings({
            trustedForwarder: address(0),
            daoURI: "http://host/",
            subdomain: "mockdao888",
            metadata: ""
        });

        // Define what plugin(s) to install and give the corresponding parameters
        DAOFactory.PluginSettings[]
            memory installSettings = new DAOFactory.PluginSettings[](1);

        bytes memory pluginInstallData = pluginSetup.encodeInstallationParams(
            manager,
            initialNumber
        );
        installSettings[0] = DAOFactory.PluginSettings({
            pluginSetupRef: PluginSetupRef({
                versionTag: getLatestTag(pluginRepo),
                pluginSetupRepo: pluginRepo
            }),
            data: pluginInstallData
        });

        // Create DAO with the plugin and record the creation event
        vm.recordLogs();
        DAOFactory.InstalledPlugin[] memory installedPlugins;
        (dao, installedPlugins) = daoFactory.createDao(
            daoSettings,
            installSettings
        );
        plugin = MyUpgradeablePlugin(installedPlugins[0].plugin);

        // Grant permissions
        dao.grant(address(plugin), manager, plugin.MANAGER_PERMISSION_ID());

        // Move DAO ownership to the owner for testing
        dao.grant(address(dao), daoOwner, dao.ROOT_PERMISSION_ID());
        dao.revoke(address(dao), address(this), dao.ROOT_PERMISSION_ID());

        // Labels
        vm.label(address(dao), "DAO");
        vm.label(address(plugin), "MyUpgradeablePlugin");

        // Moving forward to avoid proposal creations failing or getVotes() giving inconsistent values
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
    }
}
