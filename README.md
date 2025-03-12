# Enhanced Ethereum Wallet

A secure and feature-rich Ethereum wallet smart contract that can receive, store, and send ETH and ERC20 tokens.

## Features

- **ETH Management**: Securely store and transfer ETH
- **ERC20 Token Support**: Manage any ERC20 tokens
- **Security Features**:
  - Reentrancy protection
  - Daily withdrawal limits
  - Emergency pause functionality
  - Owner-only access control
- **Token Recovery**: Recover accidentally sent tokens

## Installation

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/) (for frontend integration)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/enhanced-wallet.git
   cd enhanced-wallet
   ```

2. Install dependencies:
   ```bash
   forge install
   ```

3. Compile the contracts:
   ```bash
   forge build
   ```

4. Run tests:
   ```bash
   forge test
   ```

## Usage

### Deploying the Wallet

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
