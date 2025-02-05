// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IDAO} from "@aragon/osx-commons-contracts/src/dao/IDAO.sol";
import {PluginUUPSUpgradeable} from "@aragon/osx-commons-contracts/src/plugin/PluginUUPSUpgradeable.sol";

import {IMyPlugin} from "./interfaces/IMyPlugin.sol";

/**
 * @title My Plugin
 * @notice A plugin that stores a number.
 */
contract MyPlugin is PluginUUPSUpgradeable, IMyPlugin {
    bytes32 public constant STORE_PERMISSION_ID = keccak256("STORE_PERMISSION");

    uint256 public number; // stored number

    /// @notice Initializes the plugin with a number.
    /// @param _dao The DAO associated with this plugin.
    /// @param _number The number to store.
    function initialize(IDAO _dao, uint256 _number) external initializer {
        __PluginUUPSUpgradeable_init(_dao);
        number = _number;
    }

    /// @notice Stores a new number. Caller must have STORE_PERMISSION.
    /// @param _number The new number to store.
    function storeNumber(uint256 _number) external auth(STORE_PERMISSION_ID) {
        number = _number;
    }
}
