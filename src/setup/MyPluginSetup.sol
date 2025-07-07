// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

import {IDAO, DAO} from "@aragon/osx/core/dao/DAO.sol";
import {IPluginSetup, PluginSetup, PermissionLib} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessor.sol";
import {ProxyLib} from "@aragon/osx-commons-contracts/src/utils/deployment/ProxyLib.sol";

// 3 Plugin types (use accordingly)
import {MyUpgradeablePlugin} from "../MyUpgradeablePlugin.sol";

// import {MyCloneablePlugin} from "../MyCloneablePlugin.sol";
// import {MyStaticPlugin} from "../MyStaticPlugin.sol";

/// @title MyPluginSetup
/// @notice Manages the installation and unintallation of the plugin on a DAO.
/// @dev It can work with upgradeable, cloneable and static plugins
/// @dev Release 1, Build 1
contract MyPluginSetup is PluginSetup {
    // NOTE: Choose your plugin variant (if upgradeable or cloneabe are desired)
    // constructor() PluginSetup(address(new MyCloneablePlugin())) {}
    constructor() PluginSetup(address(new MyUpgradeablePlugin())) {}

    /// @inheritdoc IPluginSetup
    function prepareInstallation(address _dao, bytes memory _installationParams)
        external
        returns (address plugin, PreparedSetupData memory preparedSetupData)
    {
        (address _managerAddress, uint256 _initialNumber) = decodeInstallationParams(_installationParams);

        // NOTE: Uncomment the code to deploy your desired plugin variant below

        // 1) Upgradeable plugin variant
        plugin = ProxyLib.deployUUPSProxy(
            implementation(), abi.encodeCall(MyUpgradeablePlugin.initialize, (IDAO(_dao), _initialNumber))
        );

        // 2) Cloneable plugin variant
        // plugin = ProxyLib.deployMinimalProxy(
        //     implementation(),
        //     abi.encodeCall(
        //         MyCloneablePlugin.initialize,
        //         (IDAO(_dao), _initialNumber)
        //     )
        // );

        // 3) Static plugin variant
        // plugin = address(new MyStaticPlugin(IDAO(_dao), _initialNumber));

        // Request permissions
        PermissionLib.MultiTargetPermission[] memory permissions = new PermissionLib.MultiTargetPermission[](2);

        // _managerAddress has MANAGER_PERMISSION_ID on the plugin
        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: plugin,
            who: _managerAddress,
            condition: PermissionLib.NO_CONDITION,
            permissionId: MyUpgradeablePlugin(implementation()).MANAGER_PERMISSION_ID()
        });

        // The pugin has EXECUTE_PERMISSION_ID on the DAO
        permissions[1] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: _dao,
            who: plugin,
            condition: PermissionLib.NO_CONDITION,
            permissionId: DAO(payable(_dao)).EXECUTE_PERMISSION_ID()
        });

        preparedSetupData.permissions = permissions;
    }

    // @dev NOTE: If you need to implement prepateUpdate():
    // @dev Extend from PluginUpgradeableSetup instead of PluginSetup
    // @dev Uncomment the function below

    // /// @inheritdoc IPluginSetup
    // function prepareUpdate(
    //     address, // _dao
    //     uint16, // _fromBuild
    //     SetupPayload calldata //  _payload
    // ) external override returns (bytes memory, PreparedSetupData memory) {
    //     revert("No prior version to update from");
    // }

    /// @inheritdoc IPluginSetup
    function prepareUninstallation(address _dao, SetupPayload calldata _payload)
        external
        view
        returns (PermissionLib.MultiTargetPermission[] memory permissions)
    {
        address _managerAddress = decodeUninstallationParams(_payload.data);

        // Request reverting the granted permissions
        permissions = new PermissionLib.MultiTargetPermission[](2);

        // _managerAddress has MANAGER_PERMISSION_ID on the plugin
        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Revoke,
            where: _payload.plugin,
            who: _managerAddress,
            condition: PermissionLib.NO_CONDITION,
            permissionId: keccak256("MANAGER_PERMISSION")
        });

        // The pugin has EXECUTE_PERMISSION_ID on the DAO
        permissions[1] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Revoke,
            where: _dao,
            who: _payload.plugin,
            condition: PermissionLib.NO_CONDITION,
            permissionId: DAO(payable(_dao)).EXECUTE_PERMISSION_ID()
        });
    }

    // Parameter helpers

    /// @notice Serialized the given parameters into encoded bytes
    /// @param _managerAddress The address to grant MANAGER_PERMISSION_ID to
    /// @param _initialNumber The initial number stored when deploying the contract
    function encodeInstallationParams(address _managerAddress, uint256 _initialNumber)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(_managerAddress, _initialNumber);
    }

    /// @notice Decodes the given bytes into the individual parameters
    /// @param _data The bytes array containing the encoded parameters
    function decodeInstallationParams(bytes memory _data)
        public
        pure
        returns (address _managerAddress, uint256 _initialNumber)
    {
        (_managerAddress, _initialNumber) = abi.decode(_data, (address, uint256));
    }

    /// @notice Serializes the given parameters into encoded bytes
    function encodeUninstallationParams(address _managerAddress) external pure returns (bytes memory) {
        return abi.encode(_managerAddress);
    }

    /// @notice Decodes the given bytes into the individual parameters
    /// @param _data The bytes array containing the encoded parameters
    function decodeUninstallationParams(bytes memory _data) public pure returns (address _managerAddress) {
        _managerAddress = abi.decode(_data, (address));
    }
}
