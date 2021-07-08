# tinlake mainnet spells

## template creation
```bash
/bin/create.sh [POOL_ID] [TEMPLATE_NAME]
```

## tests

set env
```
ETH_RPC_URL=https://mainnet.infura.io/v3/<INFURA_KEY>
```   

run tests
```bash 
make test   
```

## deploy

set env

```bash
ETH_RPC_URL=https://mainnet.infura.io/v3/<INFURA_KEY>
ETH_KEYSTORE
ETH_PASSWORD
ETH_FROM
ETH_GAS_PRICE
ETH_GAS=10000000
ETHERSCAN_API_KEY=<ETHERSCAN_API_KEY>
```

run bash commands

```bash 
make deploy
```


## archive

store deployed spells in archive using following format

```bash 
"archive/<root>/000<spell-index>_<contract-address>.sol"  
```