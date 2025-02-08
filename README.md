## Quick install
1. **[Ensure you have foundry installed](https://ethereum-blockchain-developer.com/2022-06-nft-truffle-hardhat-foundry/14-foundry-setup/)**

2. **Installing some cruical libraries into local (run in terminal)**
```shell
$ forge install Layr-Labs/eigenlayer-contracts@testnet-holesky
```
```shell
$ forge install Vectorized/solady
```

3. **Run**
- Terminal 1: Fork from specific block number, using infura as rpc
```shell
$ anvil --chain-id 31337 --fork-url https://holesky.infura.io/v3/1faa15d89b49436c92e2db024af24353 --fork-block-number 3312272
```
Terminal 2: Deploy contract (after every modification)
```shell
$ cd contracts
$ forge script script/DeployScoutManager.sol --rpc-url http://localhost:8545 --broadcast
```

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
