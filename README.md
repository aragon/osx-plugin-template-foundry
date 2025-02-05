# Lock to Vote Plugin

[![Built with Foundry](https://img.shields.io/badge/Built%20with-Foundry-FF6E3D?logo=ethereum)](https://book.getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-AGPLv3-blue.svg)](LICENSE.md)

NOTE: This repository is a work in progress, **not ready for production use yet**.

**A gas-efficient pair of governance plugins, enabling immediate voting through token locking**  
Built on Aragon OSx's modular framework, LockToVote and LockToApprove redefine DAO participation by eliminating the need for ahead of time token snapshots with an [IVotes](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/utils/IVotes.sol) compatible token. Any vanilla ERC20 can now be used to participate in DAO governance.

## Two flavours

![Overview](./img/overview.png)

### `LockToVote`

Feature rich voting with configurable modes, built for nuanced governance scenarios:

- **Multi-option voting**: Vote Yes/No/Abstain
- **Three voting modes**:
  - **Vote Replacement**: Update your vote option mid-proposal
  - **Early Execution**: Automatically execute proposals when thresholds are mathematically secured
  - **Standard Mode**: Traditional voting with append-only allocations
- **Parameterized thresholds**: Enforce a minimum participation, a certain support threshold, and a certain approval tally

### `LockToApprove`

Simple binary approvals, designed for proposals requiring straightforward consent:

- **Weighted approvals or vetoes**: Token holders lock funds to approve or object to proposals
- **Gas friendly tokens**: Avoids the overhead of tracking past token balances (ideal for ERC20 tokens without `IVotes` support)

## Architecture Overview

### Core Components

1. **LockManager**
   The custodial contract managing token locks and allowing to vote in multiple proposals with a single lock:

   - `UnlockMode` (Strict/Early) wether a token lock can be withdrawn at any time or only after all proposals with votes have ended
   - `lock()` deposits the current ERC20 allowance and allows the user to vote with it
   - `vote()`, `approve()` allow users to use the currently locked balance on a given proposal
   - Locking and voting can be batched through `lockAndApprove()`/`lockAndVote()`
   - It keeps track of the currently active proposals via `proposalCreated()` and `proposalEnded()` hooks

2. **LockToApprove**
   Implements binary approval logic:

   - `approve()`: Allocate locked tokens to support proposals
   - `clearApproval()`: Revoke the current allocation and trigger the corresponding tally updates
   - `canApprove()`

3. **LockToVote**
   Flexible voting implementation:
   - Handles `IMajorityVoting.VoteOption` votes (Yes/No/Abstain)
   - `vote()` allocates the current voting power into
     the selected voite option
   - `clearVote()`: Depending on the voting mode, revoke the current allocation and trigger the corresponding tally updates
   - `canVote()`

### Proposal Lifecycle

```solidity
token.approve(address(lockManager), 0.1 ether);

// Lock the available tokens and vote immediately
lockManager.lockAndVote(proposalId, VoteOption.Yes);

// Or lock first, vote later
token.approve(address(lockManager), 0.5 ether);
lockManager.lock();
lockManager.lockAndApprove(proposalId);

// Deposit more tokens and vote with the new balance
token.approve(address(lockManager), 5 ether);
lockManager.lockAndApprove(proposalId);

// Unlock your tokens (if the unlock mode allows it)
lockManager.unlock();
```

### Token unlocking

- **Strict Mode**: Unlock only after all associated proposals conclude
- **Early Unlock**: Unlock anytime by revoking votes via clearApproval()/clearVote()

## Get Started

To get started, ensure that [Foundry](https://getfoundry.sh/) and [Make](https://www.gnu.org/software/make/) are installed on your computer.

### Using the Makefile

The `Makefile` is the target launcher of the project. It's the recommended way to work with it. It manages the env variables of common tasks and executes only the steps that need to be run.

```
$ make
Available targets:

- make init       Check the dependencies and prompt to install if needed
- make clean      Clean the build artifacts

- make test            Run unit tests, locally
- make test-coverage   Generate an HTML coverage report under ./report

- make sync-tests       Scaffold or sync tree files into solidity tests
- make check-tests      Checks if solidity files are out of sync
- make markdown-tests   Generates a markdown file with the test definitions rendered as a tree

- make pre-deploy-testnet        Simulate a deployment to the testnet
- make pre-deploy-prodnet        Simulate a deployment to the production network

- make deploy-testnet        Deploy to the testnet and verify
- make deploy-prodnet        Deploy to the production network and verify

- make refund   Refund the remaining balance left on the deployment account
```

Run `make init`:

- It ensures that Foundry is installed
- It runs a first compilation of the project
- It copies `.env.example` into `.env`

Next, customize the values of `.env`.

### Understanding `.env.example`

The env.example file contains descriptions for all the initial settings. You don't need all of these right away but should review prior to fork tests and deployments

### Deployment Checklist

- [ ] I have cloned the official repository on my computer and I have checked out the corresponding branch
- [ ] I am using the latest official docker engine, running a Debian Linux (stable) image
  - [ ] I have run `docker run --rm -it -v .:/deployment debian:bookworm-slim`
  - [ ] I have run `apt update && apt install -y make curl git vim neovim bc`
  - [ ] I have run `curl -L https://foundry.paradigm.xyz | bash`
  - [ ] I have run `source /root/.bashrc && foundryup`
  - [ ] I have run `cd /deployment`
  - [ ] I have run `make init`
  - [ ] I have printed the contents of `.env` on the screen
- [ ] I am opening an editor on the `/deployment` folder, within the Docker container
- [ ] The `.env` file contains the correct parameters for the deployment
  - [ ] I have created a brand new burner wallet with `cast wallet new` and copied the private key to `DEPLOYMENT_PRIVATE_KEY` within `.env`
  - [ ] I have reviewed the target network and RPC URL
  - The plugin ENS subdomain
    - [ ] Contains a meaningful and unique value
  - The given OSx addresses:
    - [ ] Exist on the target network
    - [ ] Contain the latest stable official version of the OSx DAO implementation, the Plugin Setup Processor and the Plugin Repo Factory
    - [ ] I have verified the values on https://www.npmjs.com/package/@aragon/osx-commons-configs?activeTab=code > `/@aragon/osx-commons-configs/dist/deployments/json/`
- [ ] All the unit tests pass (`make test`)
- **Target test network**
  - [ ] I have run a preview deployment on the testnet
    - `make pre-deploy-testnet`
  - [ ] I have deployed my contracts successfully to the target testnet
    - `make deploy-testnet`
  - [ ] I have tested that these contracts work successfully
- [ ] My deployment wallet is a newly created account, ready for safe production deploys.
- My computer:
  - [ ] Is running in a safe physical location and a trusted network
  - [ ] It exposes no services or ports
  - [ ] The wifi or wired network used does does not have open ports to a WAN
- [ ] I have previewed my deploy without any errors
  - `make pre-deploy-prodnet`
- [ ] The deployment wallet has sufficient native token for gas
  - At least, 15% more than the estimated simulation
- [ ] Unit tests still run clean
- [ ] I have run `git status` and it reports no local changes
- [ ] The current local git branch (`main`) corresponds to its counterpart on `origin`
  - [ ] I confirm that the rest of members of the ceremony pulled the last commit of my branch and reported the same commit hash as my output for `git log -n 1`
- [ ] I have initiated the production deployment with `make deploy-prodnet`

### Post deployment checklist

- [ ] The deployment process completed with no errors
- [ ] The deployed factory was deployed by the deployment address
- [ ] The reported contracts have been created created by the newly deployed factory
- [ ] The smart contracts are correctly verified on Etherscan or the corresponding block explorer
- [ ] The output of the latest `deployment-*.log` file corresponds to the console output
- [ ] I have transferred the remaining funds of the deployment wallet to the address that originally funded it
  - `make refund`

## Manual deployment (CLI)

You can of course run all commands from the command line:

```sh
# Load the env vars
source .env
```

```sh
# run unit tests
forge test --no-match-path "test/fork/**/*.sol"
```

```sh
# Set the right RPC URL
RPC_URL="https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}"
```

```sh
# Run the deployment script

# If using Etherscan
forge script --chain "$NETWORK" script/Deploy.s.sol:Deploy --rpc-url "$RPC_URL" --broadcast --verify

# If using BlockScout
forge script --chain "$NETWORK" script/Deploy.s.sol:Deploy --rpc-url "$RPC_URL" --broadcast --verify --verifier blockscout --verifier-url "https://sepolia.explorer.mode.network/api\?"
```

If you get the error Failed to get EIP-1559 fees, add `--legacy` to the command:

```sh
forge script --chain "$NETWORK" script/Deploy.s.sol:Deploy --rpc-url "$RPC_URL" --broadcast --verify --legacy
```

If some contracts fail to verify on Etherscan, retry with this command:

```sh
forge script --chain "$NETWORK" script/Deploy.s.sol:Deploy --rpc-url "$RPC_URL" --verify --legacy --private-key "$DEPLOYMENT_PRIVATE_KEY" --resume
```

## Testing

See the [test tree](./TEST_TREE.md) file for a visual representation of the implemented tests.

Tests can be described using yaml files. They will be automatically transformed into solidity test files with [bulloak](https://github.com/alexfertel/bulloak).

Create a file with `.t.yaml` extension within the `test` folder and describe a hierarchy of test cases:

```yaml
# MyPluginTest.t.yaml

MyPluginTest:
  - given: proposal exists
    comment: Comment here
    and:
      - given: proposal is in the last stage
        and:
          - when: proposal can advance
            then:
              - it: Should return true

          - when: proposal cannot advance
            then:
              - it: Should return false

      - when: proposal is not in the last stage
        then:
          - it: should do A
            comment: This is an important remark
          - it: should do B
          - it: should do C

  - when: proposal doesn't exist
    comment: Testing edge cases here
    then:
      - it: should revert
```

Then use `make` to automatically sync the described branches into solidity test files.

```sh
$ make
Available targets:
# ...
- make sync-tests       Scaffold or sync tree files into solidity tests
- make check-tests      Checks if solidity files are out of sync
- make markdown-tests   Generates a markdown file with the test definitions rendered as a tree

$ make sync-tests
```

The final output will look like a human readable tree:

```
# MyPluginTest.tree

MyPluginTest
├── Given proposal exists // Comment here
│   ├── Given proposal is in the last stage
│   │   ├── When proposal can advance
│   │   │   └── It Should return true
│   │   └── When proposal cannot advance
│   │       └── It Should return false
│   └── When proposal is not in the last stage
│       ├── It should do A // Careful here
│       ├── It should do B
│       └── It should do C
└── When proposal doesn't exist // Testing edge cases here
    └── It should revert
```

And the given tree file will be used by bulloak to produce test file templates where tests can be addeed to.
