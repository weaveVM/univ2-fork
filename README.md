# Monorepo Setup Instructions

## Prerequisites

- Node.js (via NVM) with Node 14
- Yarn
- Foundry (for smart contracts)

## Setup

### Interface

1. Install Node 14 using NVM:
```bash
   nvm install 14
   nvm use 14
```
2. Navigate to v2-sdk folder and build:

```
cd packages/interface/v2-sdk
yarn install
yarn build
```

4. Navigate to interface folder and start the project:

```
cd ../interface
yarn install
yarn start
```

## Smart Contract
1. Navigate to Smart Contracts

```
cd packages/contracts
forge install
forge test

```

```
my-monorepo/
├── package.json
├── tsconfig.json
└── packages/
    ├── interface/
    │   ├── v2-sdk/
    │   └── src/
    └── contracts/
        └── src/
```

# Steps to Compile and Deploy the Smart Contracts

1. Once you clone the repo, run the commands `foundryup` and `forge install` to install all the dependencies.

2. You will find the `v2-core` and `v2-periphery` folders under the `lib` folder. If you make any changes in the code, you can use the file at `contracts/script/Imports.s.sol` to build each of these.

3. Calculate the `INIT_CODE_HASH` by navigating to `contracts/out/UniswapV2Pair.sol/UniswapV2Pair.json` and copying the key-value pair of the bytecode key. Paste it into the site [Keccak-256 Online Tool](https://emn178.github.io/online-tools/keccak_256.html) to calculate the hash. Copy the hash and update it in the file at `contracts/lib/v2-periphery/contracts/libraries/UniswapV2Library.sol` in the `pairFor()` function. Then, build the contracts once again.

4. Now that this is done, it's time to deploy the contracts.

5. First, navigate to the working directory - `univ2-fork/packages/contracts`. It's time to deploy `UniswapV2Factory`:

    ```sh
    forge create --rpc-url <rpc_url> --constructor-args <address_fee_setter> --private-key <private_key> lib/v2-core/contracts/UniswapV2Factory.sol:UniswapV2Factory
    ```

6. Now, let's deploy the WETH clone, i.e., `WWVM`:

    ```sh
    forge create --rpc-url <rpc_url> --private-key <private_key> contracts/test/mocks/WWVM.sol:WWVM
    ```

7. Now that we are aware of both the factory and WETH addresses, it's time to deploy the `UniswapV2Router`:

    ```sh
    forge create --rpc-url <rpc_url> --constructor-args <factory_address> <weth_address> --private-key <private_key> lib/v2-periphery/contracts/UniswapV2Router02.sol:UniswapV2Router02
    ```

8. If you want to test the router with a couple of tokens, you can deploy the mock ERC20 contracts as well:

    ```sh
    forge create --rpc-url <rpc_url> --constructor-args "Token A" "TKNA" --private-key <private_key> test/mocks/ERC20Mintable.sol:ERC20Mintable
    ```

9. Voila! That's the end of the contract deployments.

---

# Steps to Set Up the Frontend Code

This tutorial will be divided into two sections:

## 1. Setting Up the UniswapV2 SDK

1.1 Navigate to the `interface/v2-sdk` folder and run `yarn` to install dependencies.

1.2 Go to `src/constants.ts` and in the `ChainId` enum, add the chain ID of the chain where your contracts were deployed. We will be adding the Weave testnet chain ID, which is 9496. Next, change the value of `FACTORY_ADDRESS` to the address of your own V2 factory contract you deployed. Finally, change the `INIT_CODE_HASH` to the one in your `UniswapV2Library`'s `pairFor()` function.

1.3 Go to `src/entities/token.ts`. Locate the `WETH` constant and add your own `ChainId` and the address of the WETH smart contract you deployed earlier.

1.4 Go to `src/entities/currency.ts`. In the `public readonly ETHER`, change the symbol (`ETH`) and name (`Ether`) to that of your preferred chain. In our case, it has been changed to `tWVM`.

1.5 Run `yarn build`. Your v2-sdk is ready.

## 2. Setting Up the UniswapV2 Interface

2.1 Go to the `package.json` file. Under the `devDependencies` key, locate `@uniswap/sdk`. Change the value to `“file:../v2-sdk”`. Run `yarn`.

2.2 Go to `src/constants/index.ts`. Change the constant `ROUTER_ADDRESS` to the address of the Router contract we deployed. Now, add the `ChainId` of the new chain where our smart contracts were deployed, in our case Weave.

2.3 Go to `src/connectors/index.ts`. Locate the `supportedChainIds` array and add the chain ID of our own chain. It’s Weave, and the chain ID is 9496.

2.4 Check point 5 from [this guide](https://goldrush.dev/docs/unified-api/guides/how-to-clone-uniswapv2-frontend) to ensure completion.

2.5 Go to `src/components/Header/index.ts`. In the `NETWORK_LABELS` constant, add Weave to the list of values in the object.

2.6 Go to `src/constants/v1/index.ts`. In the `V1_FACTORY_ADDRESSES`, add `ChainID.WEAVE` to the list and set the value to the address of the UniswapV2 Factory contract we had deployed earlier.

2.7 Go to `/src/state/lists/hooks.ts`. In the `EMPTY_LIST` constant, add `ChainId.WEAVE` to the list of values.

2.8 Go to `/src/utils/index.ts`. In the `ETHERSCAN_PREFIXES` constant, add `9496: ‘weave’` to the list of key-value pairs.

2.9 Run `yarn start` for your frontend to compile and open in a browser.

