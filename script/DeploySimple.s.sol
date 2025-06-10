// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {PluginRepoFactory} from "@aragon/osx/framework/plugin/repo/PluginRepoFactory.sol";
import {PluginRepo} from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";
import {hashHelpers, PluginSetupRef} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessorHelpers.sol";
import {MyPluginSetup} from "../src/setup/MyPluginSetup.sol";

/**
 * This script performs the following tasks:
 * - Deploys a new PluginRepo for each available plugin
 * - Publishes a new version of each plugin (release 1, build 1)
 */
contract DeploySimpleScript is Script {
    using stdJson for string;

    address deployer;
    PluginRepoFactory pluginRepoFactory;
    string pluginEnsSubdomain;
    address pluginRepoMaintainerAddress;

    // Artifacts
    PluginRepo myPluginRepo;
    MyPluginSetup myPluginSetup;

    modifier broadcast() {
        uint256 privKey = vm.envUint("DEPLOYMENT_PRIVATE_KEY");
        vm.startBroadcast(privKey);

        deployer = vm.addr(privKey);
        console2.log("General");
        console2.log("- Deploying from:   ", deployer);
        console2.log("- Chain ID:         ", block.chainid);
        console2.log("");

        _;

        vm.stopBroadcast();
    }

    function setUp() public {
        // Pick the contract addresses from
        // https://github.com/aragon/osx/blob/main/packages/artifacts/src/addresses.json

        // Prepare the OSx factories for the current network
        pluginRepoFactory = PluginRepoFactory(vm.envAddress("PLUGIN_REPO_FACTORY_ADDRESS"));
        vm.label(address(pluginRepoFactory), "PluginRepoFactory");

        // Read the rest of environment variables
        pluginEnsSubdomain = vm.envOr("PLUGIN_ENS_SUBDOMAIN", string(""));

        // Using a random subdomain if empty
        if (bytes(pluginEnsSubdomain).length == 0) {
            pluginEnsSubdomain = string.concat("my-test-plugin-", vm.toString(block.timestamp));
        }

        pluginRepoMaintainerAddress = vm.envAddress("PLUGIN_REPO_MAINTAINER_ADDRESS");
        vm.label(pluginRepoMaintainerAddress, "Maintainer");
    }

    function run() public broadcast {
        // Publish the first version in a new plugin repo
        deployPluginRepo();

        // Done
        printDeployment();

        // Write the addresses to a JSON file
        if (!vm.envOr("SIMULATION", false)) {
            writeJsonArtifacts();
        }
    }

    function deployPluginRepo() public {
        // Plugin setup (the installer)
        myPluginSetup = new MyPluginSetup();

        // The new plugin repository
        // Publish the plugin in a new repo as release 1, build 1
        myPluginRepo = pluginRepoFactory.createPluginRepoWithFirstVersion(
            pluginEnsSubdomain, address(myPluginSetup), pluginRepoMaintainerAddress, " ", " "
        );
    }

    function printDeployment() public view {
        console2.log("MyUpgradeablePlugin:");
        console2.log("- Plugin repo:               ", address(myPluginRepo));
        console2.log("- Plugin repo maintainer:    ", pluginRepoMaintainerAddress);
        console2.log("- ENS:                       ", string.concat(pluginEnsSubdomain, ".plugin.dao.eth"));
        console2.log("");
    }

    function writeJsonArtifacts() internal {
        string memory artifacts = "output";
        artifacts.serialize("pluginRepo", address(myPluginRepo));
        artifacts.serialize("pluginRepoMaintainer", pluginRepoMaintainerAddress);
        artifacts = artifacts.serialize("pluginEnsDomain", string.concat(pluginEnsSubdomain, ".plugin.dao.eth"));

        string memory networkName = vm.envString("NETWORK_NAME");
        string memory filePath = string.concat(
            vm.projectRoot(), "/artifacts/deployment-", networkName, "-", vm.toString(block.timestamp), ".json"
        );
        artifacts.write(filePath);

        console2.log("Deployment artifacts written to", filePath);
    }
}
