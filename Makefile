.DEFAULT_TARGET: help

# Import the .env files and export their values (ignore any error if missing)
-include .env

# RULE SPECIFIC ENV VARS [optional]

# Override the verifier and block explorer parameters (network dependent)
deploy-testnet: export ETHERSCAN_API_KEY_PARAM = --etherscan-api-key $(ETHERSCAN_API_KEY)
deploy-prodnet: export ETHERSCAN_API_KEY_PARAM = --etherscan-api-key $(ETHERSCAN_API_KEY)
# deploy-testnet: export VERIFIER_TYPE_PARAM = --verifier blockscout
# deploy-testnet: export VERIFIER_URL_PARAM = --verifier-url "https://server/api\?"

# CONSTANTS

TEST_COVERAGE_SRC_FILES:=$(wildcard test/*.sol test/**/*.sol script/*.sol script/**/*.sol src/escrow/increasing/delegation/*.sol src/libs/ProxyLib.sol)
DEPLOY_SCRIPT:=script/Deploy.s.sol:Deploy
VERBOSITY:=-vvv
SHELL:=/bin/bash

SOLIDITY_VERSION=0.8.17
TEST_TREE_MARKDOWN=TEST_TREE.md
SOURCE_FILES=$(wildcard test/*.t.yaml test/integration/*.t.yaml)
TREE_FILES = $(SOURCE_FILES:.t.yaml=.tree)
TARGET_TEST_FILES = $(SOURCE_FILES:.tree=.t.sol)
MAKE_TEST_TREE=deno run ./test/script/make-test-tree.ts
MAKEFILE=Makefile

# TARGETS

.PHONY: help
help:
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_-]*:.*?## .*$$' Makefile \
		| sed -n 's/^\(.*\): \(.*\)##\(.*\)/- make \1  \3/p' \
		| sed 's/^- make    $$//g'

: ## 

.PHONY: init
init: .env ##     Check the dependencies and prompt to install if needed
	@which deno > /dev/null && echo "Deno is available" || echo "Install Deno:  curl -fsSL https://deno.land/install.sh | sh"
	@which bulloak > /dev/null && echo "bulloak is available" || echo "Install bulloak:  cargo install bulloak"

	@which forge > /dev/null || curl -L https://foundry.paradigm.xyz | bash
	@forge build
	@which lcov > /dev/null || echo "Note: lcov can be installed by running 'sudo apt install lcov'"

.PHONY: clean
clean: ##    Clean the build artifacts
	rm -f $(TREE_FILES)
	rm -f $(TEST_TREE_MARKDOWN)
	rm -Rf ./out/* lcov.info* ./report/*

: ## 

.PHONY: test
test: ##          Run unit tests, locally
	forge test $(VERBOSITY)
# forge test --no-match-path $(FORK_TEST_WILDCARD) $(VERBOSITY)

test-coverage: report/index.html ## Generate an HTML coverage report under ./report
	@which open > /dev/null && open report/index.html || echo -n
	@which xdg-open > /dev/null && xdg-open report/index.html || echo -n

report/index.html: lcov.info.pruned
	genhtml $^ -o report --branch-coverage

lcov.info.pruned: lcov.info
	lcov --remove $< -o ./$@ $^

lcov.info: $(TEST_COVERAGE_SRC_FILES)
	forge coverage --report lcov
#	forge coverage --no-match-path $(FORK_TEST_WILDCARD) --report lcov

: ## 

sync-tests: $(TREE_FILES) ##     Scaffold or sync tree files into solidity tests
	@for file in $^; do \
		if [ ! -f $${file%.tree}.t.sol ]; then \
			echo "[Scaffold]   $${file%.tree}.t.sol" ; \
			bulloak scaffold -s $(SOLIDITY_VERSION) --vm-skip -w $$file ; \
		else \
			echo "[Sync file]  $${file%.tree}.t.sol" ; \
			bulloak check --fix $$file ; \
		fi \
	done

check-tests: $(TREE_FILES) ##    Checks if solidity files are out of sync
	bulloak check $^

markdown-tests: $(TEST_TREE_MARKDOWN) ## Generates a markdown file with the test definitions rendered as a tree

# Internal targets

# Generate a markdown file with the test trees
$(TEST_TREE_MARKDOWN): $(TREE_FILES)
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

$(TREE_FILES): $(SOURCE_FILES)

%.tree: %.t.yaml
	@for file in $^; do \
	  echo "[Convert]    $$file -> $${file%.t.yaml}.tree" ; \
		cat $$file | $(MAKE_TEST_TREE) > $${file%.t.yaml}.tree ; \
	done

# Copy the .env files if not present
.env:
	cp .env.example .env
	@echo "NOTE: Edit the correct values of .env before you continue"

: ## 

#### Deployment targets ####

pre-deploy-testnet: export RPC_URL = $(TESTNET_RPC_URL)
pre-deploy-testnet: export NETWORK = $(TESTNET_NETWORK)
pre-deploy-prodnet: export RPC_URL = $(PRODNET_RPC_URL)
pre-deploy-prodnet: export NETWORK = $(PRODNET_NETWORK)

pre-deploy-testnet: pre-deploy ##      Simulate a deployment to the testnet
pre-deploy-prodnet: pre-deploy ##      Simulate a deployment to the production network

: ## 

deploy-testnet: export RPC_URL = $(TESTNET_RPC_URL)
deploy-testnet: export NETWORK = $(TESTNET_NETWORK)
deploy-prodnet: export RPC_URL = $(PRODNET_RPC_URL)
deploy-prodnet: export NETWORK = $(PRODNET_NETWORK)

deploy-testnet: export DEPLOYMENT_LOG_FILE=./deployment-$(TESTNET_NETWORK)-$(shell date +"%y-%m-%d-%H-%M").log
deploy-prodnet: export DEPLOYMENT_LOG_FILE=./deployment-$(PRODNET_NETWORK)-$(shell date +"%y-%m-%d-%H-%M").log

deploy-testnet: deploy ##      Deploy to the testnet and verify
deploy-prodnet: deploy ##      Deploy to the production network and verify

.PHONY: pre-deploy
pre-deploy:
	@echo "Simulating the deployment"
	forge script $(DEPLOY_SCRIPT) \
		--chain $(NETWORK) \
		--rpc-url $(RPC_URL) \
		$(VERBOSITY)

.PHONY: deploy
deploy: test
	@echo "Starting the deployment"
	@mkdir -p logs/
	forge script $(DEPLOY_SCRIPT) \
		--chain $(NETWORK) \
		--rpc-url $(RPC_URL) \
		--broadcast \
		--verify \
		$(VERIFIER_TYPE_PARAM) \
		$(VERIFIER_URL_PARAM) \
		$(ETHERSCAN_API_KEY_PARAM) \
		$(VERBOSITY) | tee logs/$(DEPLOYMENT_LOG_FILE)

: ## 

refund: export DEPLOYMENT_ADDRESS = $(shell cast wallet address --private-key $(DEPLOYMENT_PRIVATE_KEY))

.PHONY: refund
refund: ## Refund the balance left on the deployment account
	@echo "Refunding the remaining balance on $(DEPLOYMENT_ADDRESS)"
	@if [ -z $(REFUND_ADDRESS) -o $(REFUND_ADDRESS) = "0x0000000000000000000000000000000000000000" ]; then \
		echo "- The refund address is empty" ; \
		exit 1; \
	fi
	@BALANCE=$(shell cast balance $(DEPLOYMENT_ADDRESS) --rpc-url $(PRODNET_RPC_URL)) && \
		GAS_PRICE=$(shell cast gas-price --rpc-url $(PRODNET_RPC_URL)) && \
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
			--rpc-url $(PRODNET_RPC_URL) \
			--value $$REMAINING \
			$(REFUND_ADDRESS)
