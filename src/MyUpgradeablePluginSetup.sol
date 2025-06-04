// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.24;

import {IDAO} from "@aragon/osx/core/dao/DAO.sol";
import {IPluginSetup, PluginSetup, PermissionLib} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessor.sol";
import {ProxyLib} from "@aragon/osx-commons-contracts/src/utils/deployment/ProxyLib.sol";
import {MyUpgradeablePlugin} from "./MyUpgradeablePlugin.sol";

/// @title MyUpgradeablePluginSetup
/// @dev Release 1, Build 1
contract MyUpgradeablePluginSetup is PluginSetup {
    /// @inheritdoc IPluginSetup
    address public immutable implementation;

    /// @notice A struct to contain the parameters used to deploy a new plugin.
    struct InstallationParams {
        /// @notice The address to grant STORE_PERMISSION_ID to
        address setterAddress;
        /// @notice The initial number stored when deploying the contract
        uint256 initialNumber;
    }

    /// @notice A struct to contain the parameters used to uninstall a plugin.
    struct UninstallationParams {
        /// @notice The address to withdraw STORE_PERMISSION_ID from
        address setterAddress;
    }

    constructor() {
        implementation = address(new MyUpgradeablePlugin());
    }

    /// @inheritdoc IPluginSetup
    function prepareInstallation(
        address _dao,
        bytes memory _installationParams
    )
        external
        returns (address plugin, PreparedSetupData memory preparedSetupData)
    {
        InstallationParams memory _params = decodeInstallationParams(
            _installationParams
        );

        plugin = ProxyLib.deployUUPSProxy(
            implementation,
            abi.encodeCall(
                MyUpgradeablePlugin.initialize,
                (IDAO(_dao), _params.initialNumber)
            )
        );

        // Request permissions
        PermissionLib.MultiTargetPermission[]
            memory permissions = new PermissionLib.MultiTargetPermission[](1);

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: plugin,
            who: _params.setterAddress,
            condition: PermissionLib.NO_CONDITION,
            permissionId: implementation.STORE_PERMISSION_ID
        });

        preparedSetupData.permissions = permissions;
    }

    /// @inheritdoc IPluginSetup
    function prepareUninstallation(
        address _dao,
        SetupPayload calldata _payload
    )
        external
        pure
        returns (PermissionLib.MultiTargetPermission[] memory permissions)
    {
        UninstallationParams memory _params = decodeUninstallationParams(
            _payload.data
        );

        // Request reverting the granted permissions
        permissions = new PermissionLib.MultiTargetPermission[](1);

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Revoke,
            where: _payload.plugin,
            who: _params.setterAddress,
            condition: PermissionLib.NO_CONDITION,
            permissionId: keccak256("STORE_PERMISSION")
        });
    }

    // Parameter helpers

    /// @notice Serialized the given installation parameters into encoded bytes
    function encodeInstallationParams(
        InstallationParams memory installationParams
    ) external pure returns (bytes memory) {
        return abi.encode(installationParams);
    }

    /// @notice Decodes the given bytes into a parameters struct
    function decodeInstallationParams(
        bytes memory _data
    ) public pure returns (InstallationParams memory installationParams) {
        installationParams = abi.decode(_data, (InstallationParams));
    }

    /// @notice Serializes the given uninstallation parameters into encoded bytes
    function encodeUninstallationParams(
        UninstallationParams memory uninstallationParams
    ) external pure returns (bytes memory) {
        return abi.encode(uninstallationParams);
    }

    /// @notice Decodes the given bytes into a parameters struct
    function decodeUninstallationParams(
        bytes memory _data
    ) public pure returns (UninstallationParams memory uninstallationParams) {
        uninstallationParams = abi.decode(_data, (UninstallationParams));
    }
}
