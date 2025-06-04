// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.17;

import {IDAO} from "@aragon/osx/core/dao/DAO.sol";
import {PluginUUPSUpgradeable} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessor.sol";

/// @title My Upgradeable Plugin
/// @notice A plugin that exposes a permissioned function to store a number.
/// @dev In order to call setNumber() the caller needs to hold the MANAGER_PERMISSION
contract MyUpgradeablePlugin is PluginUUPSUpgradeable {
    bytes32 public constant MANAGER_PERMISSION_ID =
        keccak256("MANAGER_PERMISSION");

    /// @dev Added in build 1
    uint256 public number;

    /// @notice Initializes the plugin when build 1 is installed.
    /// @param _number The number to be stored.
    function initialize(IDAO _dao, uint256 _number) external initializer {
        __PluginUUPSUpgradeable_init(_dao);

        number = _number;
    }

    /// @notice Stores a new number to storage. The caller needs MANAGER_PERMISSION.
    /// @param _number The new number to be stored.
    function setNumber(uint256 _number) external auth(MANAGER_PERMISSION_ID) {
        number = _number;
    }
}
