#!/usr/bin/env bash
set -e

if [ -z "$1" ] ; then
  echo "Pool ID missing"
  exit 1
fi

if [ -z "$2" ] ; then
  echo "Template missing"
  exit 1
fi

POOL_ID=$1
TEMPLATE=$2

RELEASES=$(curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/centrifuge/tinlake-pools-mainnet/releases)
IPFS=$(echo $RELEASES | jq -r ".[0].body" | awk '/https/{print $0}')

POOLS_FILE=$(curl -s $IPFS)
NAME=$(echo $POOLS_FILE | jq -r ".[\"$POOL_ID\"].metadata.shortName")
ADDRESSES=$(echo $POOLS_FILE | jq -r ".[\"$POOL_ID\"].addresses" | jq -r 'keys[] as $k | "\taddress constant public \($k) = \(.[$k]);"')

mkdir './src/draft'
touch './src/draft/addresses.sol'

echo """
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;

// $NAME addresses at $(date)
contract Addresses {
$ADDRESSES  
}
""" > './src/draft/addresses.sol'

cat template/$TEMPLATE.sol > './src/draft/spell.sol'
cat template/$TEMPLATE.t.sol > './src/draft/spell.t.sol'