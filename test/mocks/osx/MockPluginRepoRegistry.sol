// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import {IDAO} from "@aragon/osx/src/core/dao/DAO.sol";
import {InterfaceBasedRegistry} from "@aragon/osx/src/test/utils/InterfaceBasedRegistryMock.sol";
import {IPluginRepo} from "@aragon/osx/src/framework/plugin/repo/IPluginRepo.sol";

/// @title MockPluginRepoRegistry
/// @author Aragon Association - 2022-2023
/// @notice This contract maintains an address-based registry of plugin repositories in the Aragon App DAO framework.
contract MockPluginRepoRegistry is InterfaceBasedRegistry {
    /// @notice The ID of the permission required to call the `register` function.
    // bytes32 public constant REGISTER_PLUGIN_REPO_PERMISSION_ID = keccak256("REGISTER_PLUGIN_REPO_PERMISSION");

    /// @notice Emitted if a new plugin repository is registered.
    /// @param subdomain The subdomain of the plugin repository.
    /// @param pluginRepo The address of the plugin repository.
    event PluginRepoRegistered(string subdomain, address pluginRepo);

    // /// @notice Thrown if the plugin subdomain doesn't match the regex `[0-9a-z\-]`
    // error InvalidPluginSubdomain(string subdomain);

    // /// @notice Thrown if the plugin repository subdomain is empty.
    // error EmptyPluginRepoSubdomain();

    /// @dev Used to disallow initializing the implementation contract by an attacker for extra safety.
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract by setting calling the `InterfaceBasedRegistry` base class initialize method.
    /// @param _dao The address of the managing DAO.
    function initialize(IDAO _dao) external initializer {
        bytes4 pluginRepoInterfaceId = type(IPluginRepo).interfaceId;
        __InterfaceBasedRegistry_init(_dao, pluginRepoInterfaceId);

        // subdomainRegistrar = _subdomainRegistrar;
    }

    /// @notice Registers a plugin repository with a subdomain and address.
    /// @param subdomain The subdomain of the PluginRepo.
    /// @param pluginRepo The address of the PluginRepo contract.
    function registerPluginRepo(
        string calldata subdomain,
        address pluginRepo // auth(REGISTER_PLUGIN_REPO_PERMISSION_ID)
    ) external {
        // if (!(bytes(subdomain).length > 0)) {
        //     revert EmptyPluginRepoSubdomain();
        // }
        // if (!isSubdomainValid(subdomain)) {
        //     revert InvalidPluginSubdomain({subdomain: subdomain});
        // }
        // bytes32 labelhash = keccak256(bytes(subdomain));
        // subdomainRegistrar.registerSubnode(labelhash, pluginRepo);
        // _register(pluginRepo);
        // emit PluginRepoRegistered(subdomain, pluginRepo);
    }

    /// @notice This empty reserved space is put in place to allow future versions to add new variables without shifting down storage in the inheritance chain (see [OpenZeppelin's guide about storage gaps](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps)).
    uint256[50] private __gap;
}
