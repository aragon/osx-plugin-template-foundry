// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {DAO} from "@aragon/osx/src/core/dao/DAO.sol";
import {createProxyAndCall, createSaltedProxyAndCall, predictProxyAddress} from "../../src/util/proxy.sol";
import {ALICE_ADDRESS} from "../constants.sol";
import {MyPlugin} from "../../src/MyPlugin.sol";
import {IMyPlugin} from "../../src/interfaces/IMyPlugin.sol";
import {IPlugin} from "@aragon/osx-commons-contracts/src/plugin/IPlugin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TestToken} from "../mocks/TestToken.sol";

contract DaoBuilder is Test {
    address immutable DAO_BASE = address(new DAO());
    address immutable MY_PLUGIN_BASE = address(new MyPlugin());

    struct MintEntry {
        address tokenHolder;
        uint256 amount;
    }

    uint256 number = 420_69;
    address owner = ALICE_ADDRESS;
    address[] proposers;
    MintEntry[] tokenHolders;

    function withDaoOwner(address newOwner) public returns (DaoBuilder) {
        owner = newOwner;
        return this;
    }

    function withTokenHolder(address newTokenHolder, uint256 amount) public returns (DaoBuilder) {
        tokenHolders.push(MintEntry({tokenHolder: newTokenHolder, amount: amount}));
        return this;
    }

    function withNumber(uint256 newNumber) public returns (DaoBuilder) {
        number = newNumber;
        return this;
    }

    function withProposer(address newProposer) public returns (DaoBuilder) {
        proposers.push(newProposer);
        return this;
    }

    /// @dev Creates a DAO with the given orchestration settings.
    /// @dev The setup is done on block/timestamp 0 and tests should be made on block/timestamp 1 or later.
    function build() public returns (DAO dao, MyPlugin myPlugin, IERC20 lockableToken, IERC20 underlyingToken) {
        // Deploy the DAO with `this` as root
        dao = DAO(
            payable(
                createProxyAndCall(
                    address(DAO_BASE),
                    abi.encodeCall(DAO.initialize, ("", address(this), address(0x0), ""))
                )
            )
        );

        // Deploy ERC20 token
        lockableToken = new TestToken();
        underlyingToken = new TestToken();

        if (tokenHolders.length > 0) {
            for (uint256 i = 0; i < tokenHolders.length; i++) {
                TestToken(address(lockableToken)).mint(tokenHolders[i].tokenHolder, tokenHolders[i].amount);
            }
        } else {
            TestToken(address(lockableToken)).mint(owner, 10 ether);
        }

        // Plugin and helper

        IMyPlugin targetPlugin;

        myPlugin = MyPlugin(
            createProxyAndCall(address(MY_PLUGIN_BASE), abi.encodeCall(MyPlugin.initialize, (dao, number)))
        );
        targetPlugin = IMyPlugin(address(myPlugin));

        // The plugin can execute on the DAO
        dao.grant(address(dao), address(targetPlugin), dao.EXECUTE_PERMISSION_ID());

        // The DAO can store the number
        dao.grant(address(targetPlugin), address(dao), MyPlugin(address(targetPlugin)).STORE_PERMISSION_ID());

        // Alice can store the number
        dao.grant(address(targetPlugin), ALICE_ADDRESS, MyPlugin(address(targetPlugin)).STORE_PERMISSION_ID());

        // Transfer ownership to the owner
        dao.grant(address(dao), owner, dao.ROOT_PERMISSION_ID());
        dao.revoke(address(dao), address(this), dao.ROOT_PERMISSION_ID());

        // Labels
        vm.label(address(dao), "DAO");
        vm.label(address(myPlugin), "MyPlugin");
        vm.label(address(lockableToken), "VotingToken");
        vm.label(address(underlyingToken), "UnderlyingToken");

        // Moving forward to avoid proposal creations failing or getVotes() giving inconsistent values
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);
    }
}
