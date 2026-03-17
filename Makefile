# NOTE: Choose the appropriate deployment script
DEPLOYMENT_SCRIPT ?= DeploySimple
# DEPLOYMENT_SCRIPT ?= DeployDaoWithPlugins
# DEPLOYMENT_SCRIPT ?= DeployViaFactory

# .env is imported by base.mk
include lib/foundry-env/base.mk

#

VERIFY_CONTRACTS_SCRIPT := script/verify-contracts.sh

## Verification:

.PHONY: verify-etherscan
verify-etherscan: broadcast/Deploy.s.sol/$(CHAIN_ID)/run-latest.json ## Verify the last deployment on an Etherscan (compatible) explorer
	forge build $(FORGE_BUILD_CUSTOM_PARAMS)
	bash $(VERIFY_CONTRACTS_SCRIPT) $(CHAIN_ID) $(VERIFIER) $(VERIFIER_URL) $(VERIFIER_API_KEY)

.PHONY: verify-blockscout
verify-blockscout: broadcast/Deploy.s.sol/$(CHAIN_ID)/run-latest.json ## Verify the last deployment on BlockScout
	forge build $(FORGE_BUILD_CUSTOM_PARAMS)
	bash $(VERIFY_CONTRACTS_SCRIPT) $(CHAIN_ID) $(VERIFIER) "https://$(BLOCKSCOUT_HOST_NAME)/api" $(VERIFIER_API_KEY)

.PHONY: verify-sourcify
verify-sourcify: broadcast/Deploy.s.sol/$(CHAIN_ID)/run-latest.json ## Verify the last deployment on Sourcify
	forge build $(FORGE_BUILD_CUSTOM_PARAMS)
	bash $(VERIFY_CONTRACTS_SCRIPT) $(CHAIN_ID) $(VERIFIER) "" ""
