// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

import {IDAO} from "@aragon/osx/core/dao/DAO.sol";
import {IPluginSetup, PluginSetup, PermissionLib} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessor.sol";
import {ProxyLib} from "@aragon/osx-commons-contracts/src/utils/deployment/ProxyLib.sol";
import {MyUpgradeablePlugin} from "../MyUpgradeablePlugin.sol";

/// @title MyUpgradeablePluginSetup
/// @dev Release 1, Build 1
contract MyUpgradeablePluginSetup is PluginSetup {
    constructor() PluginSetup(address(new MyUpgradeablePlugin())) {}

    /// @inheritdoc IPluginSetup
    function prepareInstallation(
        address _dao,
        bytes memory _installationParams
    )
        external
        returns (address plugin, PreparedSetupData memory preparedSetupData)
    {
        (
            address _managerAddress,
            uint256 _initialNumber
        ) = decodeInstallationParams(_installationParams);

        plugin = ProxyLib.deployUUPSProxy(
            implementation(),
            abi.encodeCall(
                MyUpgradeablePlugin.initialize,
                (IDAO(_dao), _initialNumber)
            )
        );

        // Request permissions
        PermissionLib.MultiTargetPermission[]
            memory permissions = new PermissionLib.MultiTargetPermission[](1);

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: plugin,
            who: _managerAddress,
            condition: PermissionLib.NO_CONDITION,
            permissionId: MyUpgradeablePlugin(implementation())
                .MANAGER_PERMISSION_ID()
        });

        preparedSetupData.permissions = permissions;
    }

    /// @inheritdoc IPluginSetup
    function prepareUninstallation(
        address, // _dao
        SetupPayload calldata _payload
    )
        external
        pure
        returns (PermissionLib.MultiTargetPermission[] memory permissions)
    {
        address _managerAddress = decodeUninstallationParams(_payload.data);

        // Request reverting the granted permissions
        permissions = new PermissionLib.MultiTargetPermission[](1);

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Revoke,
            where: _payload.plugin,
            who: _managerAddress,
            condition: PermissionLib.NO_CONDITION,
            permissionId: keccak256("MANAGER_PERMISSION")
        });
    }

    // Parameter helpers

    /// @notice Serialized the given parameters into encoded bytes
    /// @param _managerAddress The address to grant MANAGER_PERMISSION_ID to
    /// @param _initialNumber The initial number stored when deploying the contract
    function encodeInstallationParams(
        address _managerAddress,
        uint256 _initialNumber
    ) external pure returns (bytes memory) {
        return abi.encode(_managerAddress, _initialNumber);
    }

    /// @notice Decodes the given bytes into the individual parameters
    /// @param _data The bytes array containing the encoded parameters
    function decodeInstallationParams(
        bytes memory _data
    ) public pure returns (address _managerAddress, uint256 _initialNumber) {
        (_managerAddress, _initialNumber) = abi.decode(
            _data,
            (address, uint256)
        );
    }

    /// @notice Serializes the given parameters into encoded bytes
    function encodeUninstallationParams(
        address _managerAddress
    ) external pure returns (bytes memory) {
        return abi.encode(_managerAddress);
    }

    /// @notice Decodes the given bytes into the individual parameters
    /// @param _data The bytes array containing the encoded parameters
    function decodeUninstallationParams(
        bytes memory _data
    ) public pure returns (address _managerAddress) {
        _managerAddress = abi.decode(_data, (address));
    }
}
