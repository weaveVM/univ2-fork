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

2. Navigate to v2-sdk folder and build:
cd packages/interface/v2-sdk
yarn build

3. Navigate to interface folder and start the project:
cd ../interface
yarn start

## Smart Contract
1. cd packages/contracts
forge install

2. forge test

my-monorepo/
├── package.json
├── tsconfig.json
└── packages/
    ├── interface/
    │   ├── v2-sdk/
    │   └── src/
    └── contracts/
        └── src/
