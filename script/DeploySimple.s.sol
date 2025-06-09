// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Script, console2} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";

import {PluginRepoFactory} from "@aragon/osx/framework/plugin/repo/PluginRepoFactory.sol";
import {PluginRepo} from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";
import {hashHelpers, PluginSetupRef} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessorHelpers.sol";

import {MyUpgradeablePlugin} from "../src/MyUpgradeablePlugin.sol";
import {MyPluginSetup} from "../src/setup/MyPluginSetup.sol";

/**
This script performs the following tasks:
- Deploys a new PluginRepo for each available plugin
- Publishes a new version of each plugin (release 1, build 1)
*/
contract DeploySimpleScript is Script {
    address deployer;
    PluginRepoFactory pluginRepoFactory;
    string pluginEnsSubdomain;
    address pluginRepoMaintainerAddress;

    // Artifacts
    PluginRepo myUpgradeablePluginRepo;
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

        pluginRepoFactory = PluginRepoFactory(
            vm.envAddress("PLUGIN_REPO_FACTORY_ADDRESS")
        );
        vm.label(address(pluginRepoFactory), "PluginRepoFactory");

        pluginEnsSubdomain = vm.envOr("PLUGIN_ENS_SUBDOMAIN", string(""));

        // Using a random subdomain if empty
        if (bytes(pluginEnsSubdomain).length == 0) {
            pluginEnsSubdomain = string.concat(
                "my-upgradeable-plugin-",
                vm.toString(block.timestamp)
            );
        }

        pluginRepoMaintainerAddress = vm.envAddress(
            "PLUGIN_REPO_MAINTAINER_ADDRESS"
        );
        vm.label(pluginRepoMaintainerAddress, "Maintainer");
    }

    function run() public broadcast {
        // Publish the first version in a new plugin repo
        deployMyUpgradeablePlugin();

        // Done
        printDeployment();
    }

    function deployMyUpgradeablePlugin() public {
        // Plugin Setup (the installer)
        myPluginSetup = new MyPluginSetup();

        // Publish the plugin in a new repo as release 1, build 1
        address _initialMaintainer = pluginRepoMaintainerAddress;
        if (_initialMaintainer == address(0)) {
            // Own the repo temporarily
            // Transferring it to the DAO after it is created.
            _initialMaintainer = deployer;
        }

        myUpgradeablePluginRepo = pluginRepoFactory
            .createPluginRepoWithFirstVersion(
                pluginEnsSubdomain,
                address(myPluginSetup),
                _initialMaintainer,
                " ",
                " "
            );
    }

    function printDeployment() public view {
        console2.log("MyUpgradeablePlugin:");
        console2.log(
            "- Plugin repo:               ",
            address(myUpgradeablePluginRepo)
        );
        console2.log(
            "- Plugin repo maintainer:    ",
            pluginRepoMaintainerAddress
        );
        console2.log(
            "- ENS:                       ",
            string.concat(pluginEnsSubdomain, ".plugin.dao.eth")
        );
        console2.log("");
    }
}
