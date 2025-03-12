# MirageWallet

A secure and fully decentralized Ethereum wallet smart contract that can receive, store, and send ETH and ERC20 tokens.

## Features

- **ETH Management**: Securely store and transfer ETH
- **ERC20 Token Support**: Manage any ERC20 tokens with tracking system
- **Security Features**:
  - Reentrancy protection
  - Emergency pause functionality
  - Owner-only access control
- **Token Management**: Add/remove supported tokens
- **Batch Operations**: Withdraw multiple tokens in a single transaction
- **Token Recovery**: Recover accidentally sent tokens

## Installation

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/) (for frontend integration)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/mirage-wallet.git
   cd mirage-wallet
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

```shell
$ forge script script/DeployWallet.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
```

For local development with Anvil:

```shell
# Start Anvil
$ anvil

# Deploy the wallet (from another terminal)
$ forge script script/DeployWallet.s.sol --rpc-url http://localhost:8545 --private-key <ANVIL_PRIVATE_KEY> --broadcast
```

### Interacting with the Deployed Wallet

After deploying your wallet contract locally or on a testnet, you can interact with it using Foundry's `cast` tool.

### Getting Contract Information

```bash
# Get the wallet's ETH balance
$ cast call <WALLET_ADDRESS> "getBalance()" --rpc-url <RPC_URL>

# Check if the wallet is paused
$ cast call <WALLET_ADDRESS> "paused()" --rpc-url <RPC_URL>

# Get the owner address
$ cast call <WALLET_ADDRESS> "owner()" --rpc-url <RPC_URL>

# Get all supported tokens
$ cast call <WALLET_ADDRESS> "getSupportedTokens()" --rpc-url <RPC_URL>

# Get balances for all supported tokens
$ cast call <WALLET_ADDRESS> "getAllTokenBalances()" --rpc-url <RPC_URL>
```

### Sending ETH to the Wallet

```bash
# Send ETH to the wallet
$ cast send <WALLET_ADDRESS> --value <AMOUNT_IN_WEI> --private-key <SENDER_PRIVATE_KEY> --rpc-url <RPC_URL>
```

### Managing Tokens

```bash
# Add supported tokens
$ cast send <WALLET_ADDRESS> "addSupportedTokens(address[])" "[<TOKEN1_ADDRESS>,<TOKEN2_ADDRESS>]" --private-key <OWNER_PRIVATE_KEY> --rpc-url <RPC_URL>

# Remove a supported token
$ cast send <WALLET_ADDRESS> "removeSupportedToken(address)" <TOKEN_ADDRESS> --private-key <OWNER_PRIVATE_KEY> --rpc-url <RPC_URL>
```

### Withdrawing Funds

```bash
# Withdraw ETH (as the owner)
$ cast send <WALLET_ADDRESS> "withdraw(uint256,address)" <AMOUNT_IN_WEI> <RECIPIENT_ADDRESS> --private-key <OWNER_PRIVATE_KEY> --rpc-url <RPC_URL>

# Withdraw ERC20 tokens (as the owner)
$ cast send <WALLET_ADDRESS> "withdrawToken(address,uint256,address)" <TOKEN_ADDRESS> <AMOUNT> <RECIPIENT_ADDRESS> --private-key <OWNER_PRIVATE_KEY> --rpc-url <RPC_URL>

# Batch withdraw multiple tokens (as the owner)
$ cast send <WALLET_ADDRESS> "batchWithdrawTokens(address[],uint256[],address)" "[<TOKEN1_ADDRESS>,<TOKEN2_ADDRESS>]" "[<AMOUNT1>,<AMOUNT2>]" <RECIPIENT_ADDRESS> --private-key <OWNER_PRIVATE_KEY> --rpc-url <RPC_URL>
```

### Managing Security Settings

```bash
# Pause the wallet in case of emergency
$ cast send <WALLET_ADDRESS> "setPaused(bool)" true --private-key <OWNER_PRIVATE_KEY> --rpc-url <RPC_URL>

# Unpause the wallet
$ cast send <WALLET_ADDRESS> "setPaused(bool)" false --private-key <OWNER_PRIVATE_KEY> --rpc-url <RPC_URL>
```

### Working with ERC20 Tokens

```bash
# Check the wallet's balance of a specific token
$ cast call <WALLET_ADDRESS> "getTokenBalance(address)" <TOKEN_ADDRESS> --rpc-url <RPC_URL>

# Recover all tokens of a specific type (emergency function)
$ cast send <WALLET_ADDRESS> "recoverERC20(address)" <TOKEN_ADDRESS> --private-key <OWNER_PRIVATE_KEY> --rpc-url <RPC_URL>
```

## Example Workflow

1. Start a local Ethereum node:
   ```bash
   $ anvil
   ```

2. Deploy the wallet:
   ```bash
   $ forge script script/DeployWallet.s.sol --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
   ```

3. Send ETH to the wallet:
   ```bash
   $ cast send <DEPLOYED_WALLET_ADDRESS> --value 1000000000000000000 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://localhost:8545
   ```

4. Check the wallet's balance:
   ```bash
   $ cast call <DEPLOYED_WALLET_ADDRESS> "getBalance()" --rpc-url http://localhost:8545
   ```

5. Add supported tokens:
   ```bash
   $ cast send <DEPLOYED_WALLET_ADDRESS> "addSupportedTokens(address[])" "[<TOKEN1_ADDRESS>,<TOKEN2_ADDRESS>]" --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://localhost:8545
   ```

6. Withdraw ETH:
   ```bash
   $ cast send <DEPLOYED_WALLET_ADDRESS> "withdraw(uint256,address)" 500000000000000000 <RECIPIENT_ADDRESS> --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://localhost:8545
   ```

Anvil provides 10 test accounts with 10000 ETH each. You can use the first account as the owner.
