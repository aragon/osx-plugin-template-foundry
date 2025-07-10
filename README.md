# Aragon OSx Plugin Template 🚀

Welcome to the Foundry template for OSx plugins!

This template is designed to help get developers up and running with OSx in a few minutes.

## Features ✨

- **Foundry**: Configured with the right dependencies and settings for Aragon OSx.
- **Versatile contract starters**: [See Template Variants below](#template-variants-)
- **Deployment scripts and factories**: Starter scripts for simple plugin publishing, as well as for custom DAO deployments.
- **Flexible testing environment**: A set of tools to run unit tests, fork tests, describe use cases and prepare entire deployments in one line.
- **Multi explorer code verification**: Verify on multiple block explorers given the same deployment
- **Streamlined action runner**: A self documenting [makefile](#using-the-makefile) to manage the entire workflow
- **Code snippets and examples**

## Prerequisites 📋
- [Foundry](https://getfoundry.sh/)
- [Git](https://git-scm.com/)
- [Make](https://www.gnu.org/software/make/)

Optional:

- [Docker](https://www.docker.com) (recommended for deploying)
- [Deno](https://deno.land)  (used to scaffold the test files)

## Getting Started 🏁

[Click here](https://github.com/new?template_name=osx-plugin-template-foundry&template_owner=aragon) to create a repository from the template.

Clone your new repository and initialize it:

```bash
git clone git@github.com:<your-org>/my-plugin
cd my-plugin

# Initialize the repo
cp .env.example .env
make init
```

Edit `.env` to match your desired network and settings.

### Installing dependencies

```sh
forge install <github-org>/<repo-name>  # replace accordingly

# Use the version you need
cd lib/<repo-name>
git checkout v1.9.0

# Commit the version to use
cd -
git add lib/<repo-name>
git commit -m"Using repo-name v1.9.0"
```

Add the new package to `remappings.txt`:

```txt
@organiation/repo-name/=lib/repo-name
```

Verify the status:

```sh
git submodule status
```

### Using the Makefile

The `Makefile` is the target launcher of the project. It's the recommended way to operate the repository. It manages the env variables of common tasks and executes only the steps that need to be run.

```
$ make
Available targets:

- make help               Display the available targets

- make init               Check the dependencies and prompt to install if needed
- make clean              Clean the build artifacts

Testing lifecycle:

- make test               Run unit tests, locally
- make test-fork          Run fork tests, using RPC_URL
- make test-coverage      Generate an HTML coverage report under ./report

- make sync-tests         Scaffold or sync test definitions into solidity tests
- make check-tests        Checks if the solidity test files are out of sync
- make test-tree          Generates a markdown file with the test definitions
- make test-tree-prompt   Prints an LLM prompt to generate the test definitions for a given file
- make test-prompt        Prints an LLM prompt to implement the tests for a given contract

Deployment targets:

- make predeploy          Simulate a protocol deployment
- make deploy             Deploy the protocol, verify the source code and write to ./artifacts
- make resume             Retry pending deployment transactions, verify the code and write to ./artifacts

Verification:

- make verify-etherscan   Verify the last deployment on an Etherscan (compatible) explorer
- make verify-blockscout  Verify the last deployment on BlockScout
- make verify-sourcify    Verify the last deployment on Sourcify

- make refund             Refund the remaining balance left on the deployment account
```

## Template Variants 🌈

In order to accommodate a wide range of cases, this repo provides comprehensive examples for the following variants:

### Plugin types

- [UUPS upgradeable plugin](./src/MyUpgradeablePlugin.sol)
- [Cloneable plugin](./src/MyCloneablePlugin.sol)
- [Static plugin](./src/MyStaticPlugin.sol)

Update the code within `constructor()` and `prepareInstallation()` on the [plugin setup](./src/setup/MyPluginSetup.sol) to make it use the variant of your choice.

For upgradeable plugins, consider inheriting from `PluginUpgradeableSetup` instead of `PluginSetup`.

### Deployment flows

- [Deploying a plugin repository](./script/DeploySimple.s.sol) (simple, trusted)
- [Deploying a DAO with plugin(s) installed](./script/DeployDaoWithPlugins.s.sol) (trusted)
- [Deploying a DAO with plugin(s) via a Factory](./script/DeployViaFactory.s.sol)  (trustless)

Update `DEPLOYMENT_SCRIPT` in `Makefile` to make it use the deployment script of your choice.

### DAO builders (for testing)

- [Simple builder](./test/builders/SimpleBuilder.sol)
  - It creates a simple DAO with the available plugin(s) installed
  - It uses convenient defaults while allowing to override when needed
- [Fork Builder](./test/builders/ForkBuilder.sol)
  - It returns a full DAO setup with the available plugin(s) installed
  - It creates a network fork and uses the configured `DAO_FACTORY_ADDRESS` and `PLUGIN_REPO_FACTORY_ADDRESS` for simulating deployments
  - Like before, it uses convenient defaults while allowing to override when needed

## Testing 🔍

Using `make`:

```
$ make
[...]
Testing lifecycle:

- make test               Run unit tests, locally
- make test-fork          Run fork tests, using RPC_URL
- make test-coverage      Generate an HTML coverage report under ./report
```

Run `make test` or `make test-fork` to check the logic's accordance to the specs. The latter will require `RPC_URL` to be defined.

### Writing tests

Regular Foundry test contracts can be written as usual under the `tests` folder. 

Optionally, you may want to describe a hierarchy of scenarios using yaml files like [MyPlugin.t.yaml](./test/MyPlugin.t.yaml). These can be transformed into a solidity scaffold by running `make sync-tests`, thanks to [bulloak](https://github.com/alexfertel/bulloak).

Create a file with `.t.yaml` extension within the `test` folder and describe a hierarchy using the following structure:

```yaml
# MyPlugin.t.yaml

MyPluginTest:
  - given: The caller has no permission
    comment: The caller needs MANAGER_PERMISSION_ID
    and:
      - when: Calling setNumber()
        then:
          - it: Should revert
  - given: The caller has permission
    and:
      - when: Calling setNumber()
        then:
          - it: It should update the stored number
  - when: Calling number()
    then:
      - it: Should return the right value
```

Nodes like `when` and `given` can be nested without limitations.

Then use `make sync-tests` to automatically sync the described branches into solidity test files.

```sh
$ make
Testing lifecycle:
# ...

- make sync-tests         Scaffold or sync test definitions into solidity tests
- make check-tests        Checks if the solidity test files are out of sync
- make test-tree          Generates a markdown file with the test definitions

$ make sync-tests
```

Each yaml file generates (or syncs) a solidity test file with functions ready to be implemented. They also generate a human readable summary in [TESTS.md](./TESTS.md).

### Using LLM's to describe the expected tests

```sh
$ make
Testing lifecycle:
# ...

- make test-llm-prompt    Generates a prompt to generate the test tree for a given file

$ make test-llm-prompt src=./src/MyUpgradeablePlugin.sol
```

This command will make a prompt that you can provide to an LLM so that it assists in generating test definitions.

Copy the resulting output into a file like `test/MyUpgradeablePlugin.t.yaml` and run `make sync-tests` to get a solidity scaffold.

### Testing with a local OSx

You can deploy an in-memory, local OSx deployment to run your E2E tests on top of it.

```sh
forge install aragon/protocol-factory
```

You may need to set `via_ir` to `true` on `foundry.toml`.

Given that this repository already depends on OSx, you may want to replace the existing `remappings.txt` entry and use the OSx path provided by `protocol-factory` itself.

```diff
-@aragon/osx/=lib/osx/packages/contracts/src/

+@aragon/protocol-factory/=lib/protocol-factory/
+@aragon/osx/=lib/protocol-factory/lib/osx/packages/contracts/src/
```

Then, use the protocol factory to deploy OSx and use its contracts as you need.

```solidity
// Set the path according to your remappings.txt file
import {ProtocolFactoryBuilder} from "@aragon/protocol-factory/test/helpers/ProtocolFactoryBuilder.sol";

// Prepare an OSx factory
ProtocolFactory factory = new ProtocolFactoryBuilder().build();
factory.deployOnce();

// Get the protocol addresses
ProtocolFactory.Deployment memory deployment = factory.getDeployment();
console.log("DaoFactory", deployment.daoFactory);
```

You can even [customize these OSx deployments](https://github.com/aragon/protocol-factory?tab=readme-ov-file#if-you-need-to-override-some-parameters) if needed.

## Deployment 🚀

Check the available make targets to simulate and deploy the smart contracts:

```
- make predeploy        Simulate a protocol deployment
- make deploy           Deploy the protocol and verify the source code
```

### Deployment Checklist

When running a production deployment ceremony, you can use these steps as a reference:

- [ ] I have cloned the official repository on my computer and I have checked out the `main` branch
- [ ] I am using the latest official docker engine, running a Debian Linux (stable) image
  - [ ] I have run `docker run --rm -it -v .:/deployment debian:bookworm-slim`
  - [ ] I have run `apt update && apt install -y make curl git vim neovim bc`
  - [ ] I have run `curl -L https://foundry.paradigm.xyz | bash`
  - [ ] I have run `source /root/.bashrc && foundryup`
  - [ ] I have run `cd /deployment`
  - [ ] I have run `cp .env.example .env`
  - [ ] I have run `make init`
- [ ] I am opening an editor on the `/deployment` folder, within the Docker container
- [ ] The `.env` file contains the correct parameters for the deployment
  - [ ] I have created a new burner wallet with `cast wallet new` and copied the private key to `DEPLOYMENT_PRIVATE_KEY` within `.env`
  - [ ] I have set the correct `RPC_URL` for the network
  - [ ] I have set the correct `CHAIN_ID` for the network
  - [ ] The value of `NETWORK_NAME` is listed within `constants.mk`, at the appropriate place
  - [ ] I have set `ETHERSCAN_API_KEY` or `BLOCKSCOUT_HOST_NAME` (when relevant to the target network)
  - [ ] (TO DO: Add a step to check your own variables here)
  - [ ] I have printed the contents of `.env` to the screen
  - [ ] I am the only person of the ceremony that will operate the deployment wallet
- [ ] All the tests run clean (`make test`)
- My computer:
  - [ ] Is running in a safe location and using a trusted network
  - [ ] It exposes no services or ports
    - MacOS: `sudo lsof -iTCP -sTCP:LISTEN -nP`
    - Linux: `netstat -tulpn`
    - Windows: `netstat -nao -p tcp`
  - [ ] The wifi or wired network in use does not expose any ports to a WAN
- [ ] I have run `make predeploy` and the simulation completes with no errors
- [ ] The deployment wallet has sufficient native token for gas
  - At least, 15% more than the amount estimated during the simulation
- [ ] `make test` still runs clean
- [ ] I have run `git status` and it reports no local changes
- [ ] The current local git branch (`main`) corresponds to its counterpart on `origin`
  - [ ] I confirm that the rest of members of the ceremony pulled the last git commit on `main` and reported the same commit hash as my output for `git log -n 1`
- [ ] I have initiated the production deployment with `make deploy`

### Post deployment checklist

- [ ] The deployment process completed with no errors
- [ ] The factory contract was deployed by the deployment address
- [ ] All the project's smart contracts are correctly verified on the reference block explorer of the target network.
- [ ] The output of the latest `logs/deployment-<network>-<date>.log` file corresponds to the console output
- [ ] A file called `artifacts/deployment-<network>-<timestamp>.json` has been created, and the addresses match those logged to the screen
- [ ] I have uploaded the following files to a shared location:
  - `logs/deployment-<network>.log` (the last one)
  - `artifacts/deployment-<network>-<timestamp>.json`  (the last one)
  - `broadcast/Deploy.s.sol/<chain-id>/run-<timestamp>.json` (the last one, or `run-latest.json`)
- [ ] The rest of members confirm that the values are correct
- [ ] I have transferred the remaining funds of the deployment wallet to the address that originally funded it
  - `make refund`

This concludes the deployment ceremony.

## Contract source verification

When running a deployment with `make deploy`, Foundry will attempt to verify the contracts on the corresponding block explorer.

If you need to verify on multiple explorers or the automatic verification did not work, you have three `make` targets available:

```
$ make
[...]
Verification:

- make verify-etherscan   Verify the last deployment on an Etherscan (compatible) explorer
- make verify-blockscout  Verify the last deployment on BlockScout
- make verify-sourcify    Verify the last deployment on Sourcify
```

These targets use the last deployment data under `broadcast/Deploy.s.sol/<chain-id>/run-latest.json`.
- Ensure that the required variables are set within the `.env` file.
- Ensure that `NETWORK_NAME` is listed on the right section under `constants.mk`, according to the block explorer that you want to target

This flow will attempt to verify all the contracts in one go, but yo umay still need to issue additional manual verifications, depending on the circumstances.

### Routescan verification (manual)

```sh
$ forge verify-contract <address> <path/to/file.sol>:<contract-name> --verifier-url 'https://api.routescan.io/v2/network/<testnet|mainnet>/evm/<chain-id>/etherscan' --etherscan-api-key "verifyContract" --num-of-optimizations 200 --compiler-version 0.8.28 --constructor-args <args>
```

Where:
- `<address>` is the address of the contract to verify
- `<path/to/file.sol>:<contract-name>` is the path of the source file along with the contract name
- `<testnet|mainnet>` the type of network
- `<chain-id>` the ID of the chain
- `<args>` the constructor arguments
  - Get them with `$(cast abi-encode "constructor(address param1, uint256 param2,...)" param1 param2 ...)`

## Security 🔒

If you believe you've found a security issue, we encourage you to notify us. We welcome working with you to resolve the issue promptly.

Security Contact Email: sirt@aragon.org

Please do not use the public issue tracker to report security issues.

## Contributing 🤝

Contributions are welcome! Please read our contributing guidelines to get started.

## License 📄

This project is licensed under AGPL-3.0-or-later.

## Support 💬

For support, join our Discord server or open an issue in the repository.
