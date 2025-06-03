// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {Vm} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {DAOFactory} from "@aragon/osx/framework/dao/DAOFactory.sol";
import {PluginRepoFactory} from "@aragon/osx/framework/plugin/repo/PluginRepoFactory.sol";
import {PluginRepo} from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";
import {PluginSetupRef} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessorHelpers.sol";

import {AragonTest} from "./AragonTest.sol";

bytes32 constant INSTALLATION_APPLIED_EVENT_SELECTOR = keccak256(
    "InstallationApplied(address,address,bytes32,bytes32)"
);

contract AragonForkTest is AragonTest {
    DAOFactory internal immutable daoFactory =
        DAOFactory(vm.envOr("DAO_FACTORY_FORK_ADDRESS", address(0)));
    PluginRepoFactory internal immutable pluginRepoFactory =
        PluginRepoFactory(
            vm.envOr("PLUGIN_REPO_FACTORY_FORK_ADDRESS", address(0))
        );

    function setUp() public virtual {
        if (address(daoFactory) == address(0)) {
            revert("Please, set DAO_FACTORY_FORK_ADDRESS on your .env file");
        } else if (address(pluginRepoFactory) == address(0)) {
            revert(
                "Please, set PLUGIN_REPO_FACTORY_FORK_ADDRESS on your .env file"
            );
        }

        // Start the fork
        vm.createSelectFork(vm.envString("RPC_URL"));

        console2.log(
            "======================== E2E SETUP ======================"
        );
        console2.log("Forking from: ", vm.envString("FORKING_NETWORK"));
        console2.log("DaoFactory:   ", address(daoFactory));
        console2.log("RepoFactory:  ", address(pluginRepoFactory));
        console2.log(
            "========================================================="
        );
    }

    /// @notice Deploys a new PluginRepo and a DAO
    /// @param pluginRepoSubdomain The subdomain for the new PluginRepo
    /// @param pluginSetup The address of the plugin setup contract
    /// @param pluginInstallData The initialization data for the plugin
    function deployDaoRepoPlugin(
        string memory pluginRepoSubdomain,
        address pluginSetup,
        bytes memory pluginInstallData
    ) internal returns (DAO dao, PluginRepo repo, address plugin) {
        repo = deployRepo(pluginRepoSubdomain, pluginSetup);
        (dao, plugin) = deployDaoPlugin(repo, pluginInstallData);
    }

    /// @notice Deploys a DAO with the given PluginRepo and installation data
    /// @param pluginRepo The PluginRepo to use for the DAO
    /// @param pluginInstallData The installation data for the DAO
    /// @return dao The newly created DAO
    /// @return plugin The plugin used in the DAO
    function deployDaoPlugin(
        PluginRepo pluginRepo,
        bytes memory pluginInstallData
    ) internal returns (DAO dao, address plugin) {
        // DAO settings
        DAOFactory.DAOSettings memory daoSettings = DAOFactory.DAOSettings({
            trustedForwarder: address(0),
            daoURI: "http://host/",
            subdomain: "mockdao888",
            metadata: ""
        });

        // Plugin settings
        DAOFactory.PluginSettings[]
            memory installSettings = new DAOFactory.PluginSettings[](1);
        installSettings[0] = DAOFactory.PluginSettings({
            pluginSetupRef: PluginSetupRef({
                versionTag: getLatestTag(pluginRepo),
                pluginSetupRepo: pluginRepo
            }),
            data: pluginInstallData
        });

        // Create DAO and record the creation event
        vm.recordLogs();
        dao = daoFactory.createDao(daoSettings, installSettings);

        // Find the plugin address
        Vm.Log[] memory entries = vm.getRecordedLogs();
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] != INSTALLATION_APPLIED_EVENT_SELECTOR) {
                continue;
            }

            // The plugin address is the third topic (second event parameter)
            plugin = address(uint160(uint256(entries[i].topics[2])));
            break;
        }
    }

    /// @notice Deploys a new PluginRepo with the first version
    /// @param pluginRepoSubdomain The subdomain for the new PluginRepo
    /// @param pluginSetup The address of the plugin setup contract
    /// @return repo The address of the newly created PluginRepo
    function deployRepo(
        string memory pluginRepoSubdomain,
        address pluginSetup
    ) internal returns (PluginRepo repo) {
        repo = pluginRepoFactory.createPluginRepoWithFirstVersion({
            _subdomain: pluginRepoSubdomain,
            _pluginSetup: pluginSetup,
            _maintainer: address(this),
            _releaseMetadata: " ",
            _buildMetadata: " "
        });
    }

    /// @notice Fetches the latest tag from the PluginRepo
    /// @param repo The PluginRepo to fetch the latest tag from
    /// @return The latest tag from the PluginRepo
    function getLatestTag(
        PluginRepo repo
    ) internal view returns (PluginRepo.Tag memory) {
        PluginRepo.Version memory v = repo.getLatestVersion(
            repo.latestRelease()
        );
        return v.tag;
    }
}
