// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {DAOFactory} from "@aragon/osx/framework/dao/DAOFactory.sol";
import {PluginRepoFactory} from "@aragon/osx/framework/plugin/repo/PluginRepoFactory.sol";
import {PluginSetupProcessor} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessor.sol";
import {PluginRepo} from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";
import {DeploymentFactory} from "../src/factory/DeploymentFactory.sol";
import {MyPluginSetup} from "../src/setup/MyPluginSetup.sol";

/**
 * This factory performs the following tasks:
 * - Deploy a factory contract
 * - Store the parameters given by this script immutably on it
 * - Orchestrate the DAO and plugin(s) deployment, fully onchain
 * - Store the deployment artifacts immutably, onchain
 *
 * This script is suitable for sensitive deployments with high value at stake.
 * - The deployer wallet holds no permission on any component
 * - The parameters passed to the factory remain immutable and accessible indefinitely
 * - The deployment logic and parameters can be fully verified, end to end
 */
contract DeployViaFactoryScript is Script {
    using stdJson for string;

    // Deployment parameters (env)
    DAOFactory daoFactory;
    PluginRepoFactory pluginRepoFactory;
    PluginSetupProcessor pluginSetupProcessor;
    bytes daoMetadataUri;
    string myPluginEnsSubdomain;
    address pluginRepoMaintainer;

    // Artifacts
    DeploymentFactory factory;

    modifier broadcast() {
        uint256 privKey = vm.envUint("DEPLOYMENT_PRIVATE_KEY");
        vm.startBroadcast(privKey);

        address deployer = vm.addr(privKey);
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

        // OSx addresses for the current network
        daoFactory = DAOFactory(vm.envAddress("DAO_FACTORY_ADDRESS"));
        pluginRepoFactory = PluginRepoFactory(vm.envAddress("PLUGIN_REPO_FACTORY_ADDRESS"));
        pluginSetupProcessor = PluginSetupProcessor(vm.envAddress("PLUGIN_SETUP_PROCESSOR_ADDRESS"));

        // ENS
        myPluginEnsSubdomain = vm.envOr("PLUGIN_ENS_SUBDOMAIN", string(""));

        if (bytes(myPluginEnsSubdomain).length == 0) {
            // Using a random subdomain if empty
            myPluginEnsSubdomain = string.concat("my-test-plugin-", vm.toString(block.timestamp));
        }

        // If empty, use address(0) so that the DAO is set as the maintainer by the factory
        pluginRepoMaintainer = vm.envOr("PLUGIN_REPO_MAINTAINER_ADDRESS", address(0));
        daoMetadataUri = vm.envOr("DAO_METADATA_URI", bytes(""));

        // Labels
        vm.label(address(pluginRepoFactory), "PluginRepoFactory");
        vm.label(address(daoFactory), "DAOFactory");
        vm.label(pluginRepoMaintainer, "Maintainer");
    }

    function run() public broadcast {
        // NOTE: Set your actual plugin variables in setUp()
        address _initialManager = address(1234);
        uint256 _initialNumber = 1234567890;

        // Pass the parameters to the new factory
        DeploymentFactory.DeploymentParams memory _params = DeploymentFactory.DeploymentParams({
            // DAO params
            metadataUri: daoMetadataUri,
            // Plugin params
            initialManager: _initialManager,
            initialNumber: _initialNumber,
            // OSx contracts
            daoFactory: daoFactory,
            pluginRepoFactory: pluginRepoFactory,
            pluginSetupProcessor: pluginSetupProcessor,
            // Plugin management params
            pluginRepoMaintainer: pluginRepoMaintainer,
            myPluginEnsSubdomain: myPluginEnsSubdomain
        });

        factory = new DeploymentFactory(_params);
        factory.deployOnce();

        // Done
        printDeployment();

        // Write the addresses to a JSON file
        if (!vm.envOr("SIMULATION", false)) {
            writeJsonArtifacts();
        }
    }

    function printDeployment() public view {
        DeploymentFactory.DeploymentParams memory params = factory.getParams();
        DeploymentFactory.Deployment memory deployment = factory.getDeployment();

        console2.log("DAO:");
        console2.log("- Address:    ", address(deployment.dao));
        console2.log("");
        console2.log("MyUpgradeablePlugin:");
        console2.log("- Installed plugin:          ", address(deployment.myPlugin));
        console2.log("- Plugin repo:               ", address(deployment.myPluginRepo));
        console2.log("- Plugin repo maintainer:    ", params.pluginRepoMaintainer);
        console2.log("- ENS:                       ", string.concat(params.myPluginEnsSubdomain, ".plugin.dao.eth"));
        console2.log("");
    }

    function writeJsonArtifacts() internal {
        DeploymentFactory.DeploymentParams memory params = factory.getParams();
        DeploymentFactory.Deployment memory deployment = factory.getDeployment();

        string memory artifacts = "output";
        artifacts.serialize("dao", address(deployment.dao));

        artifacts.serialize("plugin", deployment.myPlugin);
        artifacts.serialize("pluginRepo", address(deployment.myPluginRepo));
        artifacts.serialize("pluginRepoMaintainer", params.pluginRepoMaintainer);
        artifacts =
            artifacts.serialize("pluginEnsDomain", string.concat(params.myPluginEnsSubdomain, ".plugin.dao.eth"));

        string memory networkName = vm.envString("NETWORK_NAME");
        string memory filePath = string.concat(
            vm.projectRoot(), "/artifacts/deployment-", networkName, "-", vm.toString(block.timestamp), ".json"
        );
        artifacts.write(filePath);

        console2.log("Deployment artifacts written to", filePath);
    }
}
