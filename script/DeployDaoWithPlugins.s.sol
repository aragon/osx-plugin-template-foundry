// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {DAOFactory} from "@aragon/osx/framework/dao/DAOFactory.sol";
import {PluginRepoFactory} from "@aragon/osx/framework/plugin/repo/PluginRepoFactory.sol";
import {PluginRepo} from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";
import {hashHelpers, PluginSetupRef} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessorHelpers.sol";
import {MyPluginSetup} from "../src/setup/MyPluginSetup.sol";

/**
 * This script performs the following tasks:
 * - Deploys a new PluginRepo for each available plugin
 * - Publishes a new version of each plugin (release 1, build 1)
 * - Deploys the DAO
 * - Installs the available plugins on it
 * - If no maintainer was defined for the plugin repo, it sets the new DAO as the maintaner
 *
 * NOTE:
 *
 * This script is not suitable for sensitive deployments with high value at stake.
 * - The deployer may be the temporary maintainer of the plugin repo.
 * - Use the factory variant instead.
 */
contract DeployDaoWithPluginsScript is Script {
    using stdJson for string;

    address deployer;
    PluginRepoFactory pluginRepoFactory;
    DAOFactory daoFactory;
    string daoEnsSubdomain;
    string pluginEnsSubdomain;
    address pluginRepoMaintainer;

    // Artifacts
    PluginRepo myPluginRepo;
    MyPluginSetup myPluginSetup;
    DAO dao;
    address[] installedPlugins;

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
        // Pick the contract addresses from:
        // https://github.com/aragon/osx/blob/main/packages/artifacts/src/addresses.json

        // Prepare the OSx factories for the current network
        pluginRepoFactory = PluginRepoFactory(vm.envAddress("PLUGIN_REPO_FACTORY_ADDRESS"));
        vm.label(address(pluginRepoFactory), "PluginRepoFactory");

        daoFactory = DAOFactory(vm.envAddress("DAO_FACTORY_ADDRESS"));
        vm.label(address(daoFactory), "DAOFactory");

        // Read the rest of environment variables
        daoEnsSubdomain = vm.envOr("DAO_ENS_SUBDOMAIN", string(""));
        pluginEnsSubdomain = vm.envOr("PLUGIN_ENS_SUBDOMAIN", string(""));

        // Using a random subdomain if empty
        if (bytes(pluginEnsSubdomain).length == 0) {
            pluginEnsSubdomain = string.concat("my-test-plugin-", vm.toString(block.timestamp));
        }

        // Set the DAO as the maintainer (if empty)
        pluginRepoMaintainer = vm.envOr("PLUGIN_REPO_MAINTAINER_ADDRESS", address(0));
        vm.label(pluginRepoMaintainer, "Maintainer");
    }

    function run() public broadcast {
        // Publish the first version in a new plugin repo
        deployPluginRepo();

        // Deploying the DAO
        deployDaoWithPlugins();

        // Transfer the repo ownership to the DAO if no maintainer is defined
        if (pluginRepoMaintainer == address(0)) {
            transferRepoOwnership();
        }

        // Done
        printDeployment();

        // Write the addresses to a JSON file
        if (!vm.envOr("SIMULATION", false)) {
            writeJsonArtifacts();
        }
    }

    function deployPluginRepo() public {
        // Plugin Setup (the installer)
        myPluginSetup = new MyPluginSetup();

        address _initialMaintainer = pluginRepoMaintainer;
        if (_initialMaintainer == address(0)) {
            // NOTE: The deployer owns the repo temporarily
            // Transferring it to the DAO after it is created.
            _initialMaintainer = deployer;
        }

        // The new plugin repository
        // Publish the plugin in a new repo as release 1, build 1
        myPluginRepo = pluginRepoFactory.createPluginRepoWithFirstVersion(
            pluginEnsSubdomain, address(myPluginSetup), _initialMaintainer, " ", " "
        );
    }

    function getNewDAOSettings() public view returns (DAOFactory.DAOSettings memory) {
        return DAOFactory.DAOSettings(address(0), "", daoEnsSubdomain, "");
    }

    function getNewPluginSettings() public view returns (DAOFactory.PluginSettings[] memory installPluginSettings) {
        // NOTE: Your plugin settings come here
        // Hardcoded for simplicity
        uint256 initialNumber = 50;
        bytes memory pluginSettingsData = myPluginSetup.encodeInstallationParams(address(dao), initialNumber);

        // Install from release 1, build 1
        PluginRepo.Tag memory tag = PluginRepo.Tag(1, 1);

        // MyUpgradeablePlugin params
        installPluginSettings = new DAOFactory.PluginSettings[](1);
        installPluginSettings[0] = DAOFactory.PluginSettings(PluginSetupRef(tag, myPluginRepo), pluginSettingsData);
    }

    function deployDaoWithPlugins() public {
        // Prepare the DAO and plugin install settings
        DAOFactory.DAOSettings memory daoSettings = getNewDAOSettings();

        DAOFactory.PluginSettings[] memory installPluginSettings = getNewPluginSettings();

        // Create the DAO with the requested plugins installed
        DAOFactory.InstalledPlugin[] memory _installedPlugins;
        (dao, _installedPlugins) = daoFactory.createDao(daoSettings, installPluginSettings);

        for (uint256 i = 0; i < _installedPlugins.length; i++) {
            installedPlugins.push(_installedPlugins[i].plugin);
        }
    }

    function transferRepoOwnership() public {
        // Set the DAO as a maintainer
        myPluginRepo.grant(address(myPluginRepo), address(dao), myPluginRepo.MAINTAINER_PERMISSION_ID());

        // Remove the deployer wallet as a maintainer
        myPluginRepo.revoke(address(myPluginRepo), deployer, myPluginRepo.MAINTAINER_PERMISSION_ID());

        pluginRepoMaintainer = address(dao);
    }

    function printDeployment() public view {
        console2.log("DAO:");
        console2.log("- Address:    ", address(dao));
        if (bytes(daoEnsSubdomain).length > 0) {
            console2.log("- ENS:        ", string.concat(daoEnsSubdomain, ".dao.eth"));
        }
        console2.log("");
        console2.log("MyUpgradeablePlugin:");
        console2.log("- Installed plugin:          ", address(installedPlugins[0]));
        console2.log("- Plugin repo:               ", address(myPluginRepo));
        console2.log("- Plugin repo maintainer:    ", pluginRepoMaintainer);
        console2.log("- ENS:                       ", string.concat(pluginEnsSubdomain, ".plugin.dao.eth"));
        console2.log("");
    }

    function writeJsonArtifacts() internal {
        string memory artifacts = "output";
        artifacts.serialize("dao", address(dao));

        if (bytes(daoEnsSubdomain).length > 0) {
            artifacts.serialize("daoEnsDomain", string.concat(daoEnsSubdomain, ".dao.eth"));
        }

        artifacts.serialize("plugin", installedPlugins[0]);
        artifacts.serialize("pluginRepo", address(myPluginRepo));
        artifacts.serialize("pluginRepoMaintainer", pluginRepoMaintainer);
        artifacts = artifacts.serialize("pluginEnsDomain", string.concat(pluginEnsSubdomain, ".plugin.dao.eth"));

        string memory networkName = vm.envString("NETWORK_NAME");
        string memory filePath = string.concat(
            vm.projectRoot(), "/artifacts/deployment-", networkName, "-", vm.toString(block.timestamp), ".json"
        );
        artifacts.write(filePath);

        console2.log("Deployment artifacts written to", filePath);
    }
}
