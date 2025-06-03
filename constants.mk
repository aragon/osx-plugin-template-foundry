# Grouping networks based on the block explorer they use

# Convention:
# - Production networks:    <name>
# - Test networks:          <name>-testnet

ETHERSCAN_NETWORKS := mainnet sepolia holesky optimism
BLOCKSCOUT_NETWORKS := mode
SOURCIFY_NETWORKS :=
ROUTESCAN_NETWORKS := mode-testnet

AVAILABLE_NETWORKS = $(ETHERSCAN_NETWORKS) \
	$(BLOCKSCOUT_NETWORKS) \
	$(SOURCIFY_NETWORKS) \
	$(ROUTESCAN_NETWORKS)
