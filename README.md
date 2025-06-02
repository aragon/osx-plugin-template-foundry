# Aragon OSx Plugin Template 🚀

Welcome to the Foundry template for building plugins for Aragon OSx!

This template is designed to help developers quickly set up and start creating powerful decentralized autonomous organization (DAO) plugins using Solidity and Foundry.

## Features ✨

- **Pre-configured Foundry Environment**: Set up with all necessary dependencies and configurations for Aragon OSx.
- **Sample Contracts**: Example plugins to demonstrate integration and usage.
- **Comprehensive Testing**: Pre-written tests to ensure your plugins work as expected.

## Prerequisites 📋
- Foundry
- Git

## Getting Started 🏁

To get started, clone this repository and install the required dependencies:

```bash
git clone https://github.com/aragon/osx-plugin-template-foundry my-plugin
cd my-plugin
foundryup --version stable
forge build
```

## Usage 🛠

### Building a Plugin

Create your plugin contract in the src directory. A simple plugin template is provided as `MyPlugin.sol`.

-- Additional documentation can be found at [Aragon's Developer Portal](https://devs.aragon.org/)

## Testing

Run tests to ensure your plugins are working correctly:

``` bash
forge test
```

## Deployment

Deploy your plugin to your preferred network where Aragon is deployed:

```bash
source .env
forge script script/Deploy.s.sol:Deploy --broadcast --rpc-url <RPC_URL>
```

## Contributing 🤝

Contributions are welcome! Please read our contributing guidelines to get started.

License 📄
This project is licensed under AGPL-3.0-or-later.

Support 💬
For support, join our Discord server or open an issue in the repository.
