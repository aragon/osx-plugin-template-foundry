// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

import {DAO, IDAO, Action} from "@aragon/osx/core/dao/DAO.sol";
import {PluginUUPSUpgradeable} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessor.sol";

/// @title My Upgradeable Plugin
/// @notice A plugin that exposes a permissioned function to store a number and a function that makes the DAO execute an action.
/// @dev In order to call setNumber() the caller needs to hold the MANAGER_PERMISSION
/// @dev In order for resetDaoMetadata() to work, the plugin needs to hold EXECUTE_PERMISSION_ID on the DAO
contract MyUpgradeablePlugin is PluginUUPSUpgradeable {
    bytes32 public constant MANAGER_PERMISSION_ID = keccak256("MANAGER_PERMISSION");

    /// @dev Added in build 1
    uint256 public number;

    /// @notice Initializes the plugin when build 1 is installed.
    /// @param _initialNumber The number to be stored.
    function initialize(IDAO _dao, uint256 _initialNumber) external initializer {
        __PluginUUPSUpgradeable_init(_dao);

        number = _initialNumber;
    }

    /// @notice Stores a new number to storage. The caller needs MANAGER_PERMISSION.
    /// @param _number The new number to be stored.
    function setNumber(uint256 _number) external auth(MANAGER_PERMISSION_ID) {
        number = _number;
    }

    /// @notice Tells the DAO to execute an action
    /// @dev The plugin needs to have EXECUTE_PERMISSION_ID on the DAO
    function resetDaoMetadata() external {
        // Example action(s):
        // Encoding a call to `dao.setMetadata("")`
        Action[] memory _actions = new Action[](1);
        _actions[0].to = address(dao());
        _actions[0].data = abi.encodeCall(IDAO.setMetadata, (""));

        // Can be any arbitrary value to identify the execution
        bytes32 _executionId = bytes32(block.timestamp);

        // 256 bit bitmap to indicate which actions might fail without reverting
        uint256 _failSafeMap = 0;

        // Tell the DAO to execute the given action(s)
        DAO _dao = DAO(payable(address(dao())));
        _dao.execute(_executionId, _actions, _failSafeMap);
    }

    /// @notice This empty reserved space is put in place to allow future versions to add new variables
    ///         without shifting down storage in the inheritance chain
    ///         (see [OpenZeppelin's guide about storage gaps](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps)).
    uint256[49] private __gap;
}
