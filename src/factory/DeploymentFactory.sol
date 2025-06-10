// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {DAO, IDAO} from "@aragon/osx/core/dao/DAO.sol";
import {DAOFactory} from "@aragon/osx/framework/dao/DAOFactory.sol";
import {PermissionLib} from "@aragon/osx-commons-contracts/src/permission/PermissionLib.sol";
import {PluginSetupProcessor} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessor.sol";
import {hashHelpers, PluginSetupRef} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessorHelpers.sol";
import {PluginRepoFactory} from "@aragon/osx/framework/plugin/repo/PluginRepoFactory.sol";
import {PluginRepo, IPluginSetup} from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";
import {IVotesUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import {ProxyLib} from "@aragon/osx-commons-contracts/src/utils/deployment/ProxyLib.sol";
import {MyPluginSetup} from "../setup/MyPluginSetup.sol";

// 3 Plugin types (use accordingly)
import {MyUpgradeablePlugin} from "../MyUpgradeablePlugin.sol";

// import {MyCloneablePlugin} from "../MyCloneablePlugin.sol";
// import {MyStaticPlugin} from "../MyStaticPlugin.sol";

/// @notice This contract performs an end-to-end verifiable deployment in two steps:
/// @notice (1) Setting the immutable deployment parameters (constructor) and (2) orchestrating the DAO and plugin(s) setup.
/// @notice All the deployment artifacts become read-only after the deployment.
contract DeploymentFactory {
    /// @notice The struct containing all the parameters to deploy the DAO and its plugin(s)
    struct DeploymentParams {
        // DAO params
        bytes metadataUri;
        // Plugin params
        address initialManager;
        uint256 initialNumber;
        // OSx contracts
        DAOFactory daoFactory;
        PluginRepoFactory pluginRepoFactory;
        PluginSetupProcessor pluginSetupProcessor;
        // Plugin management params
        address pluginRepoMaintainer;
        string myPluginEnsSubdomain;
    }

    struct Deployment {
        // Deployed DAO
        DAO dao;
        // Deployed Plugin(s)
        address myPlugin;
        // Deployed Helper(s)
        // Deployed Plugin repo(s)
        PluginRepo myPluginRepo;
    }

    /// @notice Thrown when attempting to call deployOnce() when the DAO is already deployed.
    error AlreadyDeployed();

    DeploymentParams params;
    Deployment deployment;

    /// @notice Initializes the factory and stores the given parameters immutably.
    /// @param _params The parameters that will be used for the one-time deployment.
    constructor(DeploymentParams memory _params) {
        params = _params;
    }

    /// @notice Uses the immutable parameters defined when deploying the contract and performs a single deployment, whose artifacts become read-only afterwards.
    function deployOnce() external {
        if (address(deployment.dao) != address(0)) {
            revert AlreadyDeployed();
        }

        IPluginSetup.PreparedSetupData memory pluginSetupData;

        // DEPLOY THE DAO (This factory is the interim owner)
        DAO dao = prepareDao();
        deployment.dao = dao;

        // DEPLOY THE PLUGIN(S)
        (deployment.myPlugin, deployment.myPluginRepo, pluginSetupData) = prepareMyPlugin(dao);

        // APPLY THE PLUGIN INSTALLATION(S)
        grantApplyInstallationPermissions(dao);

        applyPluginInstallation(dao, address(deployment.myPlugin), deployment.myPluginRepo, pluginSetupData);

        revokeApplyInstallationPermissions(dao);

        // REMOVE THIS CONTRACT AS OWNER
        revokeOwnerPermission(deployment.dao);
    }

    function prepareDao() internal returns (DAO dao) {
        // Get the implementation address from the OSx DAO Factory
        address daoBase = DAOFactory(params.daoFactory).daoBase();

        // Deploy the DAO with `daoOwner` as ROOT
        dao = DAO(
            payable(
                ProxyLib.deployUUPSProxy(
                    daoBase,
                    abi.encodeCall(
                        DAO.initialize,
                        (
                            params.metadataUri,
                            address(this), // Initial owner
                            address(0x0), // Trusted forwarder
                            "" // DAO URI (not used)
                        )
                    )
                )
            )
        );

        // Grant the DAO the necessary permissions on itself
        PermissionLib.SingleTargetPermission[] memory items = new PermissionLib.SingleTargetPermission[](3);
        items[0] =
            PermissionLib.SingleTargetPermission(PermissionLib.Operation.Grant, address(dao), dao.ROOT_PERMISSION_ID());
        items[1] = PermissionLib.SingleTargetPermission(
            PermissionLib.Operation.Grant, address(dao), dao.UPGRADE_DAO_PERMISSION_ID()
        );
        items[2] = PermissionLib.SingleTargetPermission(
            PermissionLib.Operation.Grant, address(dao), dao.REGISTER_STANDARD_CALLBACK_PERMISSION_ID()
        );

        dao.applySingleTargetPermissions(address(dao), items);
    }

    /// @notice Deploys a new plugin repo with a first version, then it prepares a new plugin instance with the given settings
    function prepareMyPlugin(DAO dao)
        internal
        returns (address plugin, PluginRepo pluginRepo, IPluginSetup.PreparedSetupData memory preparedSetupData)
    {
        // Publish the PluginSetup
        MyPluginSetup myPluginSetup = new MyPluginSetup();

        // Publish repo
        pluginRepo = PluginRepoFactory(params.pluginRepoFactory).createPluginRepoWithFirstVersion(
            params.myPluginEnsSubdomain,
            address(myPluginSetup),
            address(dao),
            " ", // Release metadata (not used)
            " " // Build metadata (not used)
        );

        // If no maintainer is defined, set the DAO as the maintainer
        if (params.pluginRepoMaintainer == address(0)) {
            params.pluginRepoMaintainer = address(dao);
        }

        dao.grant(address(pluginRepo), params.pluginRepoMaintainer, pluginRepo.MAINTAINER_PERMISSION_ID());
        // UPGRADE_REPO_PERMISSION_ID can be granted eventually

        // NOTE: Our new plugin instance parameters
        bytes memory paramsData = myPluginSetup.encodeInstallationParams(params.initialManager, params.initialNumber);

        // New plugin instance(s)
        PluginRepo.Tag memory versionTag = PluginRepo.Tag(1, 1);
        (plugin, preparedSetupData) = params.pluginSetupProcessor.prepareInstallation(
            address(dao),
            PluginSetupProcessor.PrepareInstallationParams(PluginSetupRef(versionTag, pluginRepo), paramsData)
        );
    }

    /// @notice Gets a prepared plugin installation and it applies the requested permissions
    function applyPluginInstallation(
        DAO dao,
        address plugin,
        PluginRepo pluginRepo,
        IPluginSetup.PreparedSetupData memory preparedSetupData
    ) internal {
        params.pluginSetupProcessor.applyInstallation(
            address(dao),
            PluginSetupProcessor.ApplyInstallationParams(
                PluginSetupRef(PluginRepo.Tag(1, 1), pluginRepo),
                plugin,
                preparedSetupData.permissions,
                hashHelpers(preparedSetupData.helpers)
            )
        );
    }

    /// @notice Allow this factory to apply installations
    function grantApplyInstallationPermissions(DAO dao) internal {
        // The PSP can manage permissions on the new DAO
        dao.grant(address(dao), address(params.pluginSetupProcessor), dao.ROOT_PERMISSION_ID());

        // This factory can call applyInstallation() on the PSP
        dao.grant(
            address(params.pluginSetupProcessor),
            address(this),
            params.pluginSetupProcessor.APPLY_INSTALLATION_PERMISSION_ID()
        );
    }

    /// @notice Undo the permission for this factory to apply installations
    function revokeApplyInstallationPermissions(DAO dao) internal {
        // Revoking the permission for the factory to call applyInstallation() on the PSP
        dao.revoke(
            address(params.pluginSetupProcessor),
            address(this),
            params.pluginSetupProcessor.APPLY_INSTALLATION_PERMISSION_ID()
        );

        // Revoke the PSP permission to manage permissions on the new DAO
        dao.revoke(address(dao), address(params.pluginSetupProcessor), dao.ROOT_PERMISSION_ID());
    }

    /// @notice Remove this factory as a DAO owner
    function revokeOwnerPermission(DAO dao) internal {
        dao.revoke(address(dao), address(this), dao.ROOT_PERMISSION_ID());
    }

    // Getters

    function getParams() external view returns (DeploymentParams memory) {
        return params;
    }

    function getDeployment() external view returns (Deployment memory) {
        return deployment;
    }
}
