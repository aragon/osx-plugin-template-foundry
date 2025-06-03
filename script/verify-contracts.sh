#!/bin/bash

# Script to verify all contracts from the latest 'Deploy.s.sol' script run
# on a single, specified block explorer.
# It reads deployment details from the corresponding run-latest.json broadcast file.

# Required command-line arguments:
# $1: Chain ID (e.g., 11155111 for Sepolia)
# $2: Explorer Type ("etherscan", "blockscout", "sourcify")
# $3: Explorer API URL (required for "etherscan" & "blockscout", can be empty for "sourcify")
# $4: Explorer API Key (optional, can be empty)

# Optional Environment Variables:
# COMPILER_VERSION:        Specify if contracts were compiled with a non-default version.
# OPTIMIZER_RUNS:          Number of optimizer runs if enabled and non-default.
# FORGE_VERIFY_EXTRA_ARGS: Extra arguments to pass to all forge verify-contract calls.

set -uo pipefail # Exit on unset variables and on pipeline errors

# Constants
DEPLOY_SCRIPT_FILENAME="Deploy.s.sol"

# Functions

usage() {
  echo "Usage:"
  echo "  $(basename "$0") <chain_id> <explorer_type> <explorer_api_url> [explorer_api_key]"
  echo
  echo "Example (Etherscan/Routescan):"
  echo "  $(basename "$0") 11155111 etherscan https://api-sepolia.etherscan.io/api YOUR_ETHERSCAN_KEY"
  echo
  echo "Example (Blockscout):"
  echo "  $(basename "$0") 100 blockscout https://blockscout.com/xdai/mainnet/api YOUR_BLOCKSCOUT_KEY"
  echo
  echo "Example (Sourcify):"
  echo "  $(basename "$0") 11155111 sourcify \"\" \"\""
  echo
  echo "Explorer Types: 'etherscan', 'blockscout', 'sourcify'"
  echo "API URL and Key are not used for 'sourcify' type but placeholders might be needed if your Makefile passes them."
  echo ""
  echo "Optional Environment Variables:"
  echo "  COMPILER_VERSION, OPTIMIZER_RUNS, FORGE_VERIFY_EXTRA_ARGS"
  exit 1
}

check_dependencies() {
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq to use this script."
    exit 1
  fi
  if ! command -v forge &> /dev/null; then
    echo "Error: forge is not installed. Please install Foundry to use this script."
    exit 1
  fi
}

build_common_args() {
  local constructor_args_hex="$1"
  local libraries_cli_string="$2"

  local common_args=()

  if [[ -n "$constructor_args_hex" && "$constructor_args_hex" != "null" && "$constructor_args_hex" != "0x" ]]; then
    common_args+=(--constructor-args "$constructor_args_hex")
  fi

  if [[ -n "$libraries_cli_string" ]]; then
    read -ra lib_flags <<< "$libraries_cli_string"
    for lib_flag_part in "${lib_flags[@]}"; do
        common_args+=("$lib_flag_part")
    done
  fi

  if [[ -n "${COMPILER_VERSION:-}" ]]; then
    common_args+=(--compiler-version "$COMPILER_VERSION")
  fi

  if [[ -n "${OPTIMIZER_RUNS:-}" ]]; then
    common_args+=(--num-of-optimizations "$OPTIMIZER_RUNS")
  fi

  if [[ -n "${FORGE_VERIFY_EXTRA_ARGS:-}" ]]; then
    common_args+=($FORGE_VERIFY_EXTRA_ARGS)
  fi

  if ((${#common_args[@]} > 0)); then
    printf "%s\n" "${common_args[@]}"
  fi
}

locate_source_file() {
  local contract_name="$1"

  find src lib | grep -i "/$contract_name.sol\$"
}

verify_contract() {
  local contract_address="$1"
  local contract_name="$2"
  local contract_verification_path="$3"
  local constructor_args_for_build="$4"
  local libraries_cli_for_build="$5"

  # Explorer details are global variables set in Main Logic

  echo "----------------------------------------------------------------------"

  local verify_args=()

  case "$EXPLORER_TYPE" in
    etherscan)
      if [[ -z "$EXPLORER_API_URL" ]]; then
        echo "Error: API URL is required for etherscan type."
        return 1 # Indicate failure for this specific verification
      fi
      verify_args+=(--verifier etherscan)
      verify_args+=(--verifier-url "$EXPLORER_API_URL")
      if [[ -n "$EXPLORER_API_KEY" ]]; then
        verify_args+=(--etherscan-api-key \"$EXPLORER_API_KEY\")
      fi
      ;;
    blockscout)
      if [[ -z "$EXPLORER_API_URL" ]]; then
        echo "Error: API URL is required for blockscout type."
        return 1
      fi
      verify_args+=(--verifier blockscout)
      verify_args+=(--verifier-url "$EXPLORER_API_URL")
      if [[ -n "$EXPLORER_API_KEY" ]]; then
        verify_args+=(--etherscan-api-key \"$EXPLORER_API_KEY\")
      fi
      ;;
    sourcify)
      verify_args+=(--verifier sourcify)
      if [[ -n "$EXPLORER_API_KEY" ]]; then
        verify_args+=(--etherscan-api-key \"$EXPLORER_API_KEY\")
      fi
      ;;
    *)
      echo "Error: Unknown explorer type '${EXPLORER_TYPE}'. Supported types: etherscan, blockscout, sourcify."
      return 1
      ;;
  esac

  # Optional arguments (constructor, libs, compiler, etc.)
  while IFS= read -r line; do
    verify_args+=("$line")
  done < <(build_common_args "$constructor_args_for_build" "$libraries_cli_for_build")

  # Positional arguments (last)
  verify_args+=("$contract_address")
  verify_args+=("$contract_verification_path")

  echo "forge verify-contract ${verify_args[*]}"
  echo
  if ETHERSCAN_API_KEY="$EXPLORER_API_KEY" forge verify-contract "${verify_args[@]}" ; then
    echo "[SUCCESS] ${contract_name} (${EXPLORER_TYPE})"
  else
    echo "[FAILED] ${contract_name} (${EXPLORER_TYPE})"
  fi
  echo "----------------------------------------------------------------------"
}

# Script Main Logic

check_dependencies

# CLI arguments
if [[ $# -lt 3 || $# -gt 4 ]]; then
  usage
fi

CHAIN_ID="$1"
EXPLORER_TYPE="$2"
EXPLORER_API_URL="$3"
EXPLORER_API_KEY="${4:-}"

# Validate explorer type
case "$EXPLORER_TYPE" in
  etherscan|blockscout|sourcify)
    ;;
  *)
    echo "Error: Invalid explorer_type '$EXPLORER_TYPE'."
    usage
    ;;
esac

if [[ ("$EXPLORER_TYPE" == "etherscan" || "$EXPLORER_TYPE" == "blockscout") && -z "$EXPLORER_API_URL" ]]; then
    echo "Error: Explorer API URL (argument 3) is required for type '$EXPLORER_TYPE'."
    usage
fi

RUN_LATEST_JSON_PATH="broadcast/${DEPLOY_SCRIPT_FILENAME}/${CHAIN_ID}/run-latest.json"

if [[ ! -f "$RUN_LATEST_JSON_PATH" ]]; then
  echo "Error: Broadcast file not found at ${RUN_LATEST_JSON_PATH}"
  echo "Ensure you have run 'forge script ${DEPLOY_SCRIPT_FILENAME} --chain-id ${CHAIN_ID} --broadcast ...' first."
  exit 1
fi
echo "Reading deployment data from: ${RUN_LATEST_JSON_PATH}"

jq_query=$(cat <<EOF
.transactions[] |
  select(.transactionType == "CREATE" or .transactionType == "CREATE2") |
  select(.contractAddress != null and .contractAddress != "0x0000000000000000000000000000000000000000") |
  select(.contractName != null and .contractName != "") |
  {
    address: .contractAddress,
    name: .contractName,
    constructorArgs: (.constructorArguments // "")
  } |
  "\(.address)|\(.name)|\(.constructorArgs)"
EOF
)

jq -r "$jq_query" "$RUN_LATEST_JSON_PATH" | while IFS='|' read -r contract_address contract_name constructor_args_hex libraries_cli_string; do
  if [[ -z "$contract_address" || -z "$contract_name" ]]; then
    echo "Skipping entry with missing address or name: Addr='${contract_address}', Name='${contract_name}'"
    continue
  fi

  echo ""
  echo "Processing ${contract_name} at ${contract_address}"
  contract_verification_path="$(locate_source_file "$contract_name"):${contract_name}"

  verify_contract "$contract_address" \
                  "$contract_name" \
                  "$contract_verification_path" \
                  "$constructor_args_hex" \
                  "$libraries_cli_string"
done

echo ""
echo "All contracts processed for ${EXPLORER_TYPE}."
