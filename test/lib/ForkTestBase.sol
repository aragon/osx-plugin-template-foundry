// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {Vm} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {DAOFactory} from "@aragon/osx/framework/dao/DAOFactory.sol";
import {PluginRepoFactory} from "@aragon/osx/framework/plugin/repo/PluginRepoFactory.sol";
import {PluginRepo} from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";
import {PluginSetupRef} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessorHelpers.sol";

import {TestBase} from "./TestBase.sol";

contract ForkTestBase is TestBase {
    DAOFactory internal immutable daoFactory = DAOFactory(vm.envOr("DAO_FACTORY_ADDRESS", address(0)));
    PluginRepoFactory internal immutable pluginRepoFactory =
        PluginRepoFactory(vm.envOr("PLUGIN_REPO_FACTORY_ADDRESS", address(0)));

    function setUp() public virtual {
        if (address(daoFactory) == address(0)) {
            revert("Please, set DAO_FACTORY_ADDRESS on your .env file");
        } else if (address(pluginRepoFactory) == address(0)) {
            revert("Please, set PLUGIN_REPO_FACTORY_ADDRESS on your .env file");
        }

        // Start the fork
        vm.createSelectFork(vm.envString("RPC_URL"));
    }

    /// @notice Fetches the latest tag from the PluginRepo
    /// @param repo The PluginRepo to fetch the latest tag from
    /// @return The latest tag from the PluginRepo
    function getLatestTag(PluginRepo repo) internal view returns (PluginRepo.Tag memory) {
        PluginRepo.Version memory v = repo.getLatestVersion(repo.latestRelease());
        return v.tag;
    }
}
