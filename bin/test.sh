#!/usr/bin/env bash
set -e

dapp build

echo "network = $(seth chain)"

# getSyncTimeRemaining() {
#   BLOCK_DATA=$(curl -s --location --request POST 'localhost:8545/' --header 'Content-Type: application/json' --data-raw '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}')
#   HEX_BLOCK_TIMESTAMP=$(echo $BLOCK_DATA | jq -r ".result.timestamp")
#   BLOCK_TIMESTAMP=$(printf "%d\n" $HEX_BLOCK_TIMESTAMP)
#   CURRENT_TIMESTAMP=$(date +%s)
#   DIFF=$(echo "$(($CURRENT_TIMESTAMP-$BLOCK_TIMESTAMP))")
#   echo $DIFF
# }

# while [ $(getSyncTimeRemaining) -gt 60 ]           
# do
#   echo "$(($(getSyncTimeRemaining) / 60)) min to sync remaining..."
#   sleep 10
# done


ETH_RPC_URL=https://mainnet.infura.io/v3/270d356e743d463985d05ed87c6441e8 DAPP_TEST_TIMESTAMP=$(date +%s) hevm dapp-test --verbose=1 --rpc="$ETH_RPC_URL" --json-file=out/dapp.sol.json 