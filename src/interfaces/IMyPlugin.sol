// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IDAO} from "@aragon/osx-commons-contracts/src/dao/IDAO.sol";

/// @title IMyPlugin
/// @notice Interface for MyPlugin, a plugin that stores a number.
interface IMyPlugin {
    /// @notice The ID of the permission required to call the storeNumber function.
    function STORE_PERMISSION_ID() external pure returns (bytes32);

    /// @notice Gets the stored number.
    /// @return The currently stored number.
    function number() external view returns (uint256);

    /// @notice Initializes the plugin with a number.
    /// @param _dao The DAO associated with this plugin.
    /// @param _number The number to store.
    function initialize(IDAO _dao, uint256 _number) external;

    /// @notice Stores a new number. Caller must have STORE_PERMISSION.
    /// @param _number The new number to store.
    function storeNumber(uint256 _number) external;
}
