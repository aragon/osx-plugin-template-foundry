// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {PluginUUPSUpgradeable, IDAO} from "@aragon/osx/core/plugin/PluginUUPSUpgradeable.sol";

/**
 * @title My Plugin
 * @notice A plugin that stores a number.
 */
contract MyPlugin is PluginUUPSUpgradeable {
    bytes32 public constant STORE_PERMISSION_ID = keccak256("STORE_PERMISSION");

    uint256 public number; // added in build 1

    /// @notice Initializes the plugin when build 1 is installed.
    /// @param _number The number to be stored.
    function initialize(IDAO _dao, uint256 _number) external initializer {
        __PluginUUPSUpgradeable_init(_dao);
        number = _number;
    }

    /// @notice Stores a new number to storage. Caller needs STORE_PERMISSION.
    /// @param _number The number to be stored.
    function storeNumber(uint256 _number) external auth(STORE_PERMISSION_ID) {
        number = _number;
    }
}
