.DEFAULT_TARGET: help

# Import settings and constants
include .env
include constants.mk

SHELL:=/bin/bash

# CONSTANTS

SOLIDITY_VERSION := 0.8.28
DEPLOY_SCRIPT := script/Deploy.s.sol:DeployScript
MAKE_TEST_TREE_CMD := deno run ./script/make-test-tree.ts
VERIFY_CONTRACTS_SCRIPT := script/verify-contracts.sh
TEST_TREE_MARKDOWN := TEST_TREE.md
ARTIFACTS_FOLDER := ./artifacts
LOGS_FOLDER := ./logs
VERBOSITY := -vvv

# Remove quotes
NETWORK_NAME:=$(strip $(subst ',, $(subst ",,$(NETWORK_NAME))))
CHAIN_ID:=$(strip $(subst ',, $(subst ",,$(CHAIN_ID))))

TEST_COVERAGE_SRC_FILES := $(wildcard test/*.sol test/**/*.sol src/*.sol src/**/*.sol)
TEST_SOURCE_FILES := $(wildcard test/*.t.yaml test/integration/*.t.yaml)
TEST_TREE_FILES := $(TEST_SOURCE_FILES:.t.yaml=.tree)
DEPLOYMENT_ADDRESS := $(shell cast wallet address --private-key $(DEPLOYMENT_PRIVATE_KEY) 2>/dev/null || echo "NOTE: DEPLOYMENT_PRIVATE_KEY is not properly set on .env" > /dev/stderr)

DEPLOYMENT_LOG_FILE=deployment-$(NETWORK_NAME)-$(shell date +"%y-%m-%d-%H-%M").log

# Check values

ifeq ($(filter $(NETWORK_NAME),$(AVAILABLE_NETWORKS)),)
  $(error Unknown network: $(NETWORK_NAME). Must be one of: $(AVAILABLE_NETWORKS) (see constants.mk))
endif

# Conditional assignments

ifneq ($(filter $(NETWORK_NAME), $(ETHERSCAN_NETWORKS)),)
	# VERIFIER_URL := https://api.etherscan.io/api
	VERIFIER_API_KEY := $(ETHERSCAN_API_KEY)
	VERIFIER_PARAMS := --etherscan-api-key $(ETHERSCAN_API_KEY)
endif

ifneq ($(filter $(NETWORK_NAME), $(BLOCKSCOUT_NETWORKS)),)
	VERIFIER_URL := https://$(BLOCKSCOUT_HOST_NAME)/api\?
	VERIFIER_API_KEY := ""
	VERIFIER_PARAMS = --verifier blockscout --verifier-url "$(VERIFIER_URL)"
endif

ifneq ($(filter $(NETWORK_NAME), $(SOURCIFY_NETWORKS)),)
endif

ifneq ($(filter $(NETWORK_NAME), $(ROUTESCAN_NETWORKS)),)
	VERIFIER_API_KEY := "verifyContract"

  ifeq ($(findstring -testnet, $(NETWORK_NAME)),)
  	VERIFIER_URL := https://api.routescan.io/v2/network/mainnet/evm/$(CHAIN_ID)/etherscan
  else
  	VERIFIER_URL := https://api.routescan.io/v2/network/testnet/evm/$(CHAIN_ID)/etherscan
  endif

	VERIFIER_PARAMS = --verifier-url '$(VERIFIER_URL)' --etherscan-api-key $(VERIFIER_API_KEY)
endif

# TARGETS

.PHONY: help
help: ## Display the available targets
	@echo -e "Available targets:\n"
	@cat Makefile | while IFS= read -r line; do \
	   if [[ "$$line" == "##" ]]; then \
			echo "" ; \
		elif [[ "$$line" =~ ^##\ (.*)$$ ]]; then \
			printf "\n$${BASH_REMATCH[1]}\n\n" ; \
		elif [[ "$$line" =~ ^([^:]+):(.*)##\ (.*)$$ ]]; then \
			printf "%s %-*s %s\n" "- make" 18 "$${BASH_REMATCH[1]}" "$${BASH_REMATCH[3]}" ; \
		fi ; \
	done

##

.PHONY: init
init: ## Check the dependencies and prompt to install if needed
	@which forge > /dev/null || curl -L https://foundry.paradigm.xyz | bash
	@which lcov > /dev/null || echo "Note: lcov can be installed by running 'sudo apt install lcov'"
	@forge build

.PHONY: clean
clean: ## Clean the build artifacts
	forge clean
	rm -f $(TEST_TREE_FILES)
	rm -Rf ./out/* lcov.info* ./report/*

## Testing lifecycle:

# Run tests faster, locally
test: export ETHERSCAN_API_KEY=

.PHONY: test
test: ## Run unit tests, locally
	forge test $(VERBOSITY)

test-coverage: report/index.html ## Generate an HTML coverage report under ./report
	@which open > /dev/null && open report/index.html || true
	@which xdg-open > /dev/null && xdg-open report/index.html || true

report/index.html: lcov.info
	genhtml $^ -o report

lcov.info: $(TEST_COVERAGE_SRC_FILES)
	forge coverage --report lcov

##

sync-tests: $(TEST_TREE_FILES) ## Scaffold or sync tree files into solidity tests
	@for file in $^; do \
		if [ ! -f $${file%.tree}.t.sol ]; then \
			echo "[Scaffold]   $${file%.tree}.t.sol" ; \
			bulloak scaffold -s $(SOLIDITY_VERSION) --vm-skip -w $$file ; \
		else \
			echo "[Sync file]  $${file%.tree}.t.sol" ; \
			bulloak check --fix $$file ; \
		fi \
	done

check-tests: $(TEST_TREE_FILES) ## Checks if solidity files are out of sync
	bulloak check $^

markdown-tests: $(TEST_TREE_MARKDOWN) ## Generates a markdown file with the test definitions rendered as a tree

# Generate single a markdown file with the test trees
$(TEST_TREE_MARKDOWN): $(TEST_TREE_FILES)
	@echo "[Markdown]   TEST_TREE.md"
	@echo "# Test tree definitions" > $@
	@echo "" >> $@
	@echo "Below is the graphical definition of the contract tests implemented on [the test folder](./test)" >> $@
	@echo "" >> $@

	@for file in $^; do \
		echo "\`\`\`" >> $@ ; \
		cat $$file >> $@ ; \
		echo "\`\`\`" >> $@ ; \
		echo "" >> $@ ; \
	done

# Internal dependencies and transformations

$(TEST_TREE_FILES): $(TEST_SOURCE_FILES)
	@if ! command -v deno >/dev/null 2>&1; then \
	    echo "Note: deno can be installed by running 'curl -fsSL https://deno.land/install.sh | sh'" ; \
	    exit 1 ; \
	fi
	@if ! command -v bulloak >/dev/null 2>&1; then \
	    echo "Note: bulloak can be installed by running 'cargo install bulloak'" ; \
	    exit 1 ; \
	fi

%.tree: %.t.yaml
	@for file in $^; do \
	  echo "[Convert]    $$file -> $${file%.t.yaml}.tree" ; \
		cat $$file | $(MAKE_TEST_TREE_CMD) > $${file%.t.yaml}.tree ; \
	done

## Deployment targets:

predeploy: export SIMULATE=true

.PHONY: predeploy
predeploy: ## Simulate a protocol deployment
	@echo "Simulating the deployment"
	forge script $(DEPLOY_SCRIPT) \
		--rpc-url $(RPC_URL) \
		$(VERBOSITY)

.PHONY: deploy
deploy: test ## Deploy the protocol, verify the source code and write to ./artifacts
	@echo "Starting the deployment"
	@mkdir -p $(LOGS_FOLDER) $(ARTIFACTS_FOLDER)
	forge script $(DEPLOY_SCRIPT) \
		--rpc-url $(RPC_URL) \
		--retries 10 \
		--delay 8 \
		--broadcast \
		--verify \
		$(VERIFIER_PARAMS) \
		$(VERBOSITY) 2>&1 | tee $(LOGS_FOLDER)/$(DEPLOYMENT_LOG_FILE)

## Verification:

.PHONY: verify-etherscan
verify-etherscan: broadcast/Deploy.s.sol/$(CHAIN_ID)/run-latest.json ## Verify the last deployment on an Etherscan compatible explorer
	bash $(VERIFY_CONTRACTS_SCRIPT) $(CHAIN_ID) etherscan $(VERIFIER_URL) $(VERIFIER_API_KEY)

.PHONY: verify-blockscout
verify-blockscout: broadcast/Deploy.s.sol/$(CHAIN_ID)/run-latest.json ## Verify the last deployment on BlockScout
	bash $(VERIFY_CONTRACTS_SCRIPT) $(CHAIN_ID) blockscout $(VERIFIER_URL) $(VERIFIER_API_KEY)

.PHONY: verify-sourcify
verify-sourcify: broadcast/Deploy.s.sol/$(CHAIN_ID)/run-latest.json ## Verify the last deployment on Sourcify
	bash $(VERIFY_CONTRACTS_SCRIPT) $(CHAIN_ID) sourcify "" ""

##

.PHONY: refund
refund: ## Refund the remaining balance left on the deployment account
	@echo "Refunding the remaining balance on $(DEPLOYMENT_ADDRESS)"
	@if [ -z $(REFUND_ADDRESS) -o $(REFUND_ADDRESS) = "0x0000000000000000000000000000000000000000" ]; then \
		echo "- The refund address is empty" ; \
		exit 1; \
	fi
	@BALANCE=$(shell cast balance $(DEPLOYMENT_ADDRESS) --rpc-url $(RPC_URL)) && \
		GAS_PRICE=$(shell cast gas-price --rpc-url $(RPC_URL)) && \
		REMAINING=$$(echo "$$BALANCE - $$GAS_PRICE * 21000" | bc) && \
		\
		ENOUGH_BALANCE=$$(echo "$$REMAINING > 0" | bc) && \
		if [ "$$ENOUGH_BALANCE" = "0" ]; then \
			echo -e "- No balance can be refunded: $$BALANCE wei\n- Minimum balance: $${REMAINING:1} wei" ; \
			exit 1; \
		fi ; \
		echo -n -e "Summary:\n- Refunding: $$REMAINING (wei)\n- Recipient: $(REFUND_ADDRESS)\n\nContinue? (y/N) " && \
		\
		read CONFIRM && \
		if [ "$$CONFIRM" != "y" ]; then echo "Aborting" ; exit 1; fi ; \
		\
		cast send --private-key $(DEPLOYMENT_PRIVATE_KEY) \
			--rpc-url $(RPC_URL) \
			--value $$REMAINING \
			$(REFUND_ADDRESS)
