#!/usr/bin/env bash
set -e

if [ -z "$1" ] ; then
  echo "Pool ID missing"
  exit 1
fi

if [ -z "$2" ] ; then
  echo "Contract to migrate missing"
  exit 1
fi

POOL_ID=$1
CONTRACT_TO_MIGRATE=$2

POOLS_FILE=$(curl -s https://cloudflare-ipfs.com/ipfs/QmVwBZwhJPyP8ThbZ3m6D9i59mFJPNAKHFoi4SgAzyX1K9)
NAME=$(echo $POOLS_FILE | jq -r ".[\"$POOL_ID\"].metadata.shortName")
ADDRESSES=$(echo $POOLS_FILE | jq -r ".[\"$POOL_ID\"].addresses" | jq -r 'keys[] as $k | "\taddress constant public \($k) = \(.[$k]);"')

echo """
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;

// $NAME addresses at $(date)
contract Addresses {
$ADDRESSES  
}
""" > './src/addresses.sol'

cat template/$2-migration.sol > './src/spell.sol'
cat template/$2-migration.t.sol > './src/spell.t.sol'