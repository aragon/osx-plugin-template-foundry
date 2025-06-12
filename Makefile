.DEFAULT_TARGET: help

# Import settings and constants
include .env
include llm.mk

SHELL:=/bin/bash

# CONSTANTS

# NOTE: Choose the appropriate deployment script
DEPLOYMENT_SCRIPT := script/DeploySimple.s.sol:DeploySimpleScript
# DEPLOYMENT_SCRIPT := script/DeployDaoWithPlugins.s.sol:DeployDaoWithPluginsScript
# DEPLOYMENT_SCRIPT := script/DeployViaFactory.s.sol:DeployViaFactoryScript

SOLC_VERSION := $(shell cat foundry.toml | grep solc | cut -d= -f2 | xargs echo || echo "0.8.28")
SUPPORTED_VERIFIERS := etherscan blockscout sourcify routescan-mainnet routescan-testnet
MAKE_TEST_TREE_CMD := deno run ./script/make-test-tree.ts
VERIFY_CONTRACTS_SCRIPT := script/verify-contracts.sh
TEST_TREE_MARKDOWN := TESTS.md
ARTIFACTS_FOLDER := ./artifacts
LOGS_FOLDER := ./logs
VERBOSITY := -vvv

# Remove quotes
NETWORK_NAME:=$(strip $(subst ',, $(subst ",,$(NETWORK_NAME))))
CHAIN_ID:=$(strip $(subst ',, $(subst ",,$(CHAIN_ID))))
VERIFIER:=$(strip $(subst ',, $(subst ",,$(VERIFIER))))

TEST_COVERAGE_SRC_FILES := $(wildcard test/*.sol test/**/*.sol src/*.sol src/**/*.sol)
TEST_SOURCE_FILES := $(wildcard test/*.t.yaml test/integration/*.t.yaml)
TEST_TREE_FILES := $(TEST_SOURCE_FILES:.t.yaml=.tree)
DEPLOYMENT_ADDRESS := $(shell cast wallet address --private-key $(DEPLOYMENT_PRIVATE_KEY) 2>/dev/null || echo "NOTE: DEPLOYMENT_PRIVATE_KEY is not properly set on .env" > /dev/stderr)

DEPLOYMENT_LOG_FILE=deployment-$(NETWORK_NAME)-$(shell date +"%y-%m-%d-%H-%M").log

# Check values

ifeq ($(filter $(VERIFIER),$(SUPPORTED_VERIFIERS)),)
  $(error Unknown verifier: $(VERIFIER). It must be one of: $(SUPPORTED_VERIFIERS))
endif

# Conditional assignments

ifeq ($(VERIFIER), etherscan)
	# VERIFIER_URL := https://api.etherscan.io/api
	VERIFIER_API_KEY := $(ETHERSCAN_API_KEY)
	VERIFIER_PARAMS := --verifier $(VERIFIER) --etherscan-api-key $(ETHERSCAN_API_KEY)
endif

ifeq ($(VERIFIER), blockscout)
	VERIFIER_URL := https://$(BLOCKSCOUT_HOST_NAME)/api\?
	VERIFIER_API_KEY := ""
	VERIFIER_PARAMS = --verifier $(VERIFIER) --verifier-url "$(VERIFIER_URL)"
endif

# ifeq ($(VERIFIER), sourcify)
# endif

ifneq ($(filter $(VERIFIER), routescan-mainnet routescan-testnet),)
	ifeq ($(VERIFIER), routescan-mainnet)
		VERIFIER_URL := https://api.routescan.io/v2/network/mainnet/evm/$(CHAIN_ID)/etherscan
	else
		VERIFIER_URL := https://api.routescan.io/v2/network/testnet/evm/$(CHAIN_ID)/etherscan
	endif

	VERIFIER := custom
	VERIFIER_API_KEY := "verifyContract"
	VERIFIER_PARAMS = --verifier $(VERIFIER) --verifier-url '$(VERIFIER_URL)' --etherscan-api-key $(VERIFIER_API_KEY)
endif

# When invoked like `make deploy slow=true`
ifeq ($(slow),true)
	SLOW_FLAG := --slow
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
	forge test $(VERBOSITY) --no-match-path ./test/fork-tests/*

.PHONY: test-fork
test-fork: ## Run fork tests, using RPC_URL
	forge test $(VERBOSITY) --match-path ./test/fork-tests/*

test-coverage: report/index.html ## Generate an HTML coverage report under ./report
	@which open > /dev/null && open report/index.html || true
	@which xdg-open > /dev/null && xdg-open report/index.html || true

report/index.html: lcov.info
	genhtml $^ -o report

lcov.info: $(TEST_COVERAGE_SRC_FILES)
	forge coverage --report lcov

##

sync-tests: $(TEST_TREE_FILES) ## Scaffold or sync test definitions into solidity tests
	@for file in $^; do \
		if [ ! -f $${file%.tree}.t.sol ]; then \
			echo "[Scaffold]   $${file%.tree}.t.sol" ; \
			bulloak scaffold -s $(SOLC_VERSION) --vm-skip -w $$file ; \
		else \
			echo "[Sync file]  $${file%.tree}.t.sol" ; \
			bulloak check --fix $$file ; \
		fi \
	done

	@make test-tree

check-tests: $(TEST_TREE_FILES) ## Checks if the solidity test files are out of sync
	bulloak check $^

test-tree: $(TEST_TREE_MARKDOWN) ## Generates a markdown file with the test definitions


test-llm-prompt: export PROMPT=$(TEST_TREE_GENERATION_PROMPT)

.PHONY: test-llm-prompt
test-llm-prompt: ## Generates a prompt to generate the test tree for a given file
	@if [ -z "$(file)" ] ; then \
		echo "Invoke like:" ; \
		echo "  $$ make $(@) file=./path/to/file" ; \
		echo ; \
		exit 1 ; \
	fi
	@stat $(file) > /dev/null
	@/bin/bash -c 'printf "%s\n" "$$PROMPT"'
	@echo
	@echo "\`\`\`"
	@cat $(file)
	@echo "\`\`\`"

# Generate single a markdown file with the test trees
$(TEST_TREE_MARKDOWN): $(TEST_TREE_FILES)
	@echo "[Markdown]   $(@)"
	@echo "# Test tree definitions" > $@
	@echo "" >> $@
	@echo "Below is the graphical summary of the tests described within [test/*.t.yaml](./test)" >> $@
	@echo "" >> $@

	@for file in $^; do \
		echo "\`\`\`" >> $@ ; \
		cat $$file >> $@ ; \
		echo "\`\`\`" >> $@ ; \
	done

# Internal dependencies and transformations

$(TEST_TREE_FILES): $(TEST_SOURCE_FILES)

%.tree: %.t.yaml
	@if ! command -v deno >/dev/null 2>&1; then \
	    echo "Note: deno can be installed by running 'curl -fsSL https://deno.land/install.sh | sh'" ; \
	    exit 1 ; \
	fi
	@if ! command -v bulloak >/dev/null 2>&1; then \
	    echo "Note: bulloak can be installed by running 'cargo install bulloak'" ; \
	    exit 1 ; \
	fi

	@for file in $^; do \
	  echo "[Convert]    $$file -> $${file%.t.yaml}.tree" ; \
		cat $$file | $(MAKE_TEST_TREE_CMD) > $${file%.t.yaml}.tree ; \
	done

## Deployment targets:

predeploy: export SIMULATION=true

.PHONY: predeploy
predeploy: ## Simulate a protocol deployment
	@echo "Simulating the deployment"
	forge script $(DEPLOYMENT_SCRIPT) \
		--rpc-url $(RPC_URL) \
		$(VERBOSITY)

.PHONY: deploy
deploy: test ## Deploy the protocol, verify the source code and write to ./artifacts
	@echo "Starting the deployment"
	@mkdir -p $(LOGS_FOLDER) $(ARTIFACTS_FOLDER)
	forge script $(DEPLOYMENT_SCRIPT) \
		--rpc-url $(RPC_URL) \
		--retries 10 \
		--delay 8 \
		--broadcast \
		$(SLOW_FLAG) \
		--verify \
		$(VERIFIER_PARAMS) \
		$(VERBOSITY) 2>&1 | tee -a $(LOGS_FOLDER)/$(DEPLOYMENT_LOG_FILE)

.PHONY: resume
resume: test ## Retry pending deployment transactions, verify the code and write to ./artifacts
	@echo "Retrying the deployment"
	@mkdir -p $(LOGS_FOLDER) $(ARTIFACTS_FOLDER)
	forge script $(DEPLOYMENT_SCRIPT) \
		--rpc-url $(RPC_URL) \
		--retries 10 \
		--delay 8 \
		--broadcast \
		$(SLOW_FLAG) \
		--verify \
		--resume \
		$(VERIFIER_PARAMS) \
		$(VERBOSITY) 2>&1 | tee -a $(LOGS_FOLDER)/$(DEPLOYMENT_LOG_FILE)

## Verification:

.PHONY: verify-etherscan
verify-etherscan: broadcast/Deploy.s.sol/$(CHAIN_ID)/run-latest.json ## Verify the last deployment on an Etherscan (compatible) explorer
	forge build
	bash $(VERIFY_CONTRACTS_SCRIPT) $(CHAIN_ID) $(VERIFIER) $(VERIFIER_URL) $(VERIFIER_API_KEY)

.PHONY: verify-blockscout
verify-blockscout: broadcast/Deploy.s.sol/$(CHAIN_ID)/run-latest.json ## Verify the last deployment on BlockScout
	forge build
	bash $(VERIFY_CONTRACTS_SCRIPT) $(CHAIN_ID) $(VERIFIER) https://$(BLOCKSCOUT_HOST_NAME)/api $(VERIFIER_API_KEY)

.PHONY: verify-sourcify
verify-sourcify: broadcast/Deploy.s.sol/$(CHAIN_ID)/run-latest.json ## Verify the last deployment on Sourcify
	forge build
	bash $(VERIFY_CONTRACTS_SCRIPT) $(CHAIN_ID) $(VERIFIER) "" ""

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

# Other: Troubleshooting and helpers

.PHONY: gas-price
gas-price:
	cast gas-price --rpc-url $(RPC_URL)

.PHONY: balance
balance:
	cast balance $(DEPLOYMENT_ADDRESS) --rpc-url $(RPC_URL)

.PHONY: clean-nonces
clean-nonces:
	for nonce in $(nonces); do \
	  make clean-nonce nonce=$$nonce ; \
	done

.PHONY: clean-nonce
clean-nonce:
	cast send --private-key $(DEPLOYMENT_PRIVATE_KEY) \
 			--rpc-url $(RPC_URL) \
 			--value 0 \
      --nonce $(nonce) \
 			$(DEPLOYMENT_ADDRESS)
