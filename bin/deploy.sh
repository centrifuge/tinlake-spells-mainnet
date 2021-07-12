#!/usr/bin/env bash
set -e

export ETH_GAS=10000000
export GASNOW_PRICE_ESTIMATE="rapid"
export ETH_GAS_PRICE=$(curl -s "https://www.gasnow.org/api/v3/gas/price?utm_source=tinlake-deploy" | jq -r ".data.$GASNOW_PRICE_ESTIMATE")

echo "ETH_RPC_URL = $ETH_RPC_URL"
echo "ETH_FROM = $ETH_FROM"
echo "ETH_GAS_PRICE = $(printf %.0f $(echo "$ETH_GAS_PRICE/10^9" | bc -l)) gwei"
echo "ETH_GAS = $(printf %.0f $(echo "$ETH_GAS/10^6" | bc -l)) million"

echo "solc version = $(echo $DAPP_SOLC_VERSION)"
echo "network = $(seth chain)"
echo "balance = $(echo "$(seth balance $ETH_FROM)/10^18" | bc -l) ETH"

read -p "Ready to deploy? [y/n] " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

dapp build
dapp create --verify "src/draft/spell.sol:TinlakeSpell"