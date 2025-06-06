// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Script, console2} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";

import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {DAOFactory} from "@aragon/osx/framework/dao/DAOFactory.sol";
import {PluginRepoFactory} from "@aragon/osx/framework/plugin/repo/PluginRepoFactory.sol";
import {PluginRepo} from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";
import {hashHelpers, PluginSetupRef} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessorHelpers.sol";

import {MyUpgradeablePlugin} from "../src/MyUpgradeablePlugin.sol";
import {MyUpgradeablePluginSetup} from "../src/setup/MyUpgradeablePluginSetup.sol";

/// @notice This contract deploys a new DAO and installs the plugin(s) on it
contract DeployDaoWithPluginsScript is Script {
    address deployer;
    PluginRepoFactory pluginRepoFactory;
    DAOFactory daoFactory;
    string daoEnsSubdomain;
    string pluginEnsSubdomain;
    address pluginRepoMaintainerAddress;

    // Artifacts
    PluginRepo myUpgradeablePluginRepo;
    MyUpgradeablePluginSetup myUpgradeablePluginSetup;
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
        // Pick the contract addresses from
        // https://github.com/aragon/osx/blob/main/packages/artifacts/src/addresses.json

        pluginRepoFactory = PluginRepoFactory(
            vm.envAddress("PLUGIN_REPO_FACTORY_ADDRESS")
        );
        vm.label(address(pluginRepoFactory), "PluginRepoFactory");

        daoFactory = DAOFactory(vm.envAddress("DAO_FACTORY_ADDRESS"));
        vm.label(address(daoFactory), "DAOFactory");

        daoEnsSubdomain = vm.envOr("DAO_ENS_SUBDOMAIN", string(""));
        pluginEnsSubdomain = vm.envOr("PLUGIN_ENS_SUBDOMAIN", string(""));

        // Using a random subdomain if empty
        if (bytes(pluginEnsSubdomain).length == 0) {
            pluginEnsSubdomain = string.concat(
                "my-upgradeable-plugin-",
                vm.toString(block.timestamp)
            );
        }

        // Using the DAO's address if empty
        pluginRepoMaintainerAddress = vm.envOr(
            "PLUGIN_REPO_MAINTAINER_ADDRESS",
            address(0)
        );
    }

    function run() public broadcast {
        // Publish the first version in a new plugin repo
        deployMyUpgradeablePlugin();

        // Deploying the DAO
        deployDaoWithPlugins();

        // Transfer the repo ownership to the DAO if no maintainer is defined
        if (pluginRepoMaintainerAddress == address(0)) {
            transferRepoOwnership();
        }

        // Done
        printDeployment();
    }

    function deployMyUpgradeablePlugin() public {
        // Plugin Setup (the installer)
        myUpgradeablePluginSetup = new MyUpgradeablePluginSetup();

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
                address(myUpgradeablePluginSetup),
                _initialMaintainer,
                " ",
                " "
            );
    }

    function getDAOSettings()
        public
        view
        returns (DAOFactory.DAOSettings memory)
    {
        return DAOFactory.DAOSettings(address(0), "", daoEnsSubdomain, "");
    }

    function getInstallPluginSettings()
        public
        view
        returns (DAOFactory.PluginSettings[] memory installPluginSettings)
    {
        // Hardcoded setting for simplicity
        uint256 initialNumber = 50;
        bytes memory pluginSettingsData = myUpgradeablePluginSetup
            .encodeInstallationParams(address(dao), initialNumber);

        // Install from release 1, build 1
        PluginRepo.Tag memory tag = PluginRepo.Tag(1, 1);

        // MyUpgradeablePlugin params
        installPluginSettings = new DAOFactory.PluginSettings[](1);
        installPluginSettings[0] = DAOFactory.PluginSettings(
            PluginSetupRef(tag, myUpgradeablePluginRepo),
            pluginSettingsData
        );
    }

    function deployDaoWithPlugins() public {
        // Prepare the DAO and plugin install settings
        DAOFactory.DAOSettings memory daoSettings = getDAOSettings();

        DAOFactory.PluginSettings[]
            memory installPluginSettings = getInstallPluginSettings();

        // Create the DAO with the requested plugins installed
        DAOFactory.InstalledPlugin[] memory _installedPlugins;
        (dao, _installedPlugins) = daoFactory.createDao(
            daoSettings,
            installPluginSettings
        );

        for (uint256 i = 0; i < _installedPlugins.length; i++) {
            installedPlugins.push(_installedPlugins[i].plugin);
        }
    }

    function transferRepoOwnership() public {
        // Set the DAO as a maintainer
        myUpgradeablePluginRepo.grant(
            address(myUpgradeablePluginRepo),
            address(dao),
            myUpgradeablePluginRepo.MAINTAINER_PERMISSION_ID()
        );

        // Remove the deployer wallet as a maintainer
        myUpgradeablePluginRepo.revoke(
            address(myUpgradeablePluginRepo),
            deployer,
            myUpgradeablePluginRepo.MAINTAINER_PERMISSION_ID()
        );

        pluginRepoMaintainerAddress = address(dao);
    }

    function printDeployment() public view {
        console2.log("DAO:");
        console2.log("- Address:    ", address(dao));
        if (bytes(daoEnsSubdomain).length > 0) {
            console2.log(
                "- ENS:        ",
                string.concat(daoEnsSubdomain, ".dao.eth")
            );
        }
        console2.log("");
        console2.log("MyUpgradeablePlugin:");
        console2.log(
            "- Plugin address:            ",
            address(installedPlugins[0])
        );
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
