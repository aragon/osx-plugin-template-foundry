// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {DAO} from "@aragon/osx/src/core/dao/DAO.sol";
import {IVotesUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import {MyPluginSetup} from "../src/setup/MyPluginSetup.sol";
import {PluginRepoFactory} from "@aragon/osx/src/framework/plugin/repo/PluginRepoFactory.sol";
import {PluginRepo} from "@aragon/osx/src/framework/plugin/repo/PluginRepo.sol";
import {PluginSetupProcessor} from "@aragon/osx/src/framework/plugin/setup/PluginSetupProcessor.sol";
import {TestToken} from "../test/mocks/TestToken.sol";

contract Deploy is Script {
    modifier broadcast() {
        uint256 privKey = vm.envUint("DEPLOYMENT_PRIVATE_KEY");
        vm.startBroadcast(privKey);
        console.log("Deploying from:", vm.addr(privKey));

        _;

        vm.stopBroadcast();
    }

    function run() public broadcast {
        address maintainer = vm.envAddress("PLUGIN_MAINTAINER");
        address pluginRepoFactory = vm.envAddress("PLUGIN_REPO_FACTORY");
        string memory myPluginEnsSubdomain = vm.envString("MY_PLUGIN_REPO_ENS_SUBDOMAIN");


        // Deploy the plugin setup's
        (address myPluginSetup, PluginRepo myPluginRepo) = prepareMyPlugin(
            maintainer,
            PluginRepoFactory(pluginRepoFactory),
            myPluginEnsSubdomain
        );


        console.log("Chain ID:", block.chainid);

        console.log("");

        console.log("Plugins");
        console.log("- MyPluginSetup:", myPluginSetup);
        console.log("");

        console.log("Plugin repositories");
        console.log("- MyPlugin repository:", address(myPluginRepo));
    }

    function prepareMyPlugin(
        address maintainer,
        PluginRepoFactory pluginRepoFactory,
        string memory ensSubdomain
    ) internal returns (address pluginSetup, PluginRepo) {
        // Publish repo
        MyPluginSetup _pluginSetup = new MyPluginSetup();

        PluginRepo pluginRepo = pluginRepoFactory.createPluginRepoWithFirstVersion(
            ensSubdomain, // ENS repo subdomain left empty
            address(_pluginSetup),
            maintainer,
            " ",
            " "
        );
        return (address(_pluginSetup), pluginRepo);
    }

}
