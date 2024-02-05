## StakeManager Contract

**The StakeManager contract provides functionalities for users to stake tokens, unstake after a certain period, and for admins to slash stakes if necessary.**

## Getting Started
These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

## Prerequisites
-   **Metamask or any Ethereum wallet for interacting with Ethereum networks.**
-   **Ether in a wallet on the Goerli testnet for deployment and transaction fees.**
    **Foundry is required to compile and test the contracts locally.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Installing

1. Clone the Repository
```shell
git clone git@github.com:bezerrablockchain/stakeManager.git
cd stakeManager
```

2. Install Foundry [https://book.getfoundry.sh/getting-started/installation]
**Verify the installation with:**
```shell
forge --version
cast --version
```

3. Install the dependencies
```shell
forge install
```

4. Compile the contract
```shell
forge build
```

## .env
**Create you locally .env file based on existing .env.example.  Basic fields are:**
-   OPENZEPPELIN_BASH_PATH: If you are a windows developer you may need to set where is located you git bash binary file
-   GOERLY_RPC_URL: set with your node as a sevice given RPC URL
-   PRIVATE_KEY: set the private key to deploy the contract
-   ETHERSCAN_API_KEY: set your ETHERSCAN api key to verify the contract if is needed

**Execute the command bellow to load your env constants to your environment:**
```shell
$ source .env
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Deploy

```shell
$ forge script script/StakeManagerScript --broadcast --rpc-url $GOERLI_RPC_URL
```

### Cast

```shell
$ cast <subcommand>
```
