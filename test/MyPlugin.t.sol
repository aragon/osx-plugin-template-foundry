// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {DAO} from "@aragon/osx/core/dao/DAO.sol";

import {DaoUnauthorized} from "@aragon/osx/core/utils/auth.sol";
import {AragonTest} from "./base/AragonTest.sol";
import {MyPluginSetup} from "../src/MyPluginSetup.sol";
import {MyPlugin} from "../src/MyPlugin.sol";

abstract contract MyPluginTest is AragonTest {
    DAO internal dao;
    MyPlugin internal plugin;
    MyPluginSetup internal setup;
    uint256 internal constant NUMBER = 420;

    function setUp() public virtual {
        setup = new MyPluginSetup();
        bytes memory setupData = abi.encode(NUMBER);

        (DAO _dao, address _plugin) = createMockDaoWithPlugin(setup, setupData);

        dao = _dao;
        plugin = MyPlugin(_plugin);
    }
}

contract MyPluginInitializeTest is MyPluginTest {
    function setUp() public override {
        super.setUp();
    }

    function test_initialize() public {
        assertEq(address(plugin.dao()), address(dao));
        assertEq(plugin.number(), NUMBER);
    }

    function test_reverts_if_reinitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        plugin.initialize(dao, 69);
    }
}

contract MyPluginStoreNumberTest is MyPluginTest {
    function setUp() public override {
        super.setUp();
    }

    function test_store_number() public {
        vm.prank(address(dao));
        plugin.storeNumber(69);
        assertEq(plugin.number(), 69);
    }

    function test_reverts_if_not_auth() public {
        // error DaoUnauthorized({dao: address(_dao),  where: _where,  who: _who,permissionId: _permissionId });
        vm.expectRevert(
            abi.encodeWithSelector(
                DaoUnauthorized.selector,
                dao,
                plugin,
                address(this),
                keccak256("STORE_PERMISSION")
            )
        );
        plugin.storeNumber(69);
    }
}
