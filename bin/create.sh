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

# TODO: this should be loaded from the repo
IPFS_HASH="QmbiZYqHhL1So5SV5mwEL1tfxMR3GHWUTYkkJ9C5pyRgWL"

POOLS_FILE=$(curl -s https://cloudflare-ipfs.com/ipfs/$IPFS_HASH)
NAME=$(echo $POOLS_FILE | jq -r ".[\"$POOL_ID\"].metadata.shortName")
ADDRESSES=$(echo $POOLS_FILE | jq -r ".[\"$POOL_ID\"].addresses" | jq -r 'keys[] as $k | "\taddress constant public \($k) = \(.[$k]);"')

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