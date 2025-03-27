# MetaFi - Restaked Liquidity Pool Hook (RLP Hook)

## Overview
MetaFi is a cross-chain Uniswap v4 hook that enables Liquidity Providers (LPs) to restake their LP positions via EigenLayer. By doing so, LPs contribute to securing Actively Validated Services (AVSs) such as price oracles and rollup sequencers while earning additional EigenLayer rewards. This innovation enhances capital efficiency by transforming idle LP tokens into an active security mechanism.

## Benefits
- **Dual Yield:** LPs benefit from both swap fees and EigenLayer staking rewards.
- **Enhanced Security:** EigenLayer AVSs gain deeper liquidity and stronger security from restaked LP positions.
- **Capital Efficiency:** Instead of LP tokens sitting idle, they are put to work securing decentralized infrastructure.

## How It Works

### Swapping on Uniswap v4
Users can swap tokens on Uniswap v4 as usual. Additionally, they have the option to stake their tokens for extra rewards.

### Staking Process
1. **Initial Staking on Lido**
   - Before staking on EigenLayer, the tokens are first staked on Lido Finance.
   - This step ensures users earn staking rewards from Lido (e.g., receiving stETH in return).

2. **Restaking on EigenLayer**
   - The staked tokens (e.g., stETH or equivalent) are then restaked via EigenLayer.
   - This process enables any token to be used for staking.

### Actively Validated Services (AVS) Contribution
Restaked tokens contribute to securing Actively Validated Services (AVS) such as:
- A decentralized price oracle
- A rollup sequencer

### Rewards Distribution
Liquidity Providers (LPs) benefit in multiple ways:
- Earn Uniswap v4 swap fees.
- Receive Lido staking rewards.
- Gain additional EigenLayer restaking rewards.

By leveraging multiple staking layers, users maximize their yield while maintaining the liquidity benefits of Uniswap v4.

## Technology Track
MetaFi is built under the sponsorship of:
- **Chainlink CCIP** – for secure cross-chain communication.
- **EigenLayer** – for decentralized security and staking.
- **Uniswap Foundation** - providing the core infrastructure for liquidity provisioning and enabling seamless integration of Uniswap v4 hooks for enhanced LP utility.

## Tech Stack
- **Foundry** – A powerful development, testing, and deployment framework for Ethereum smart contracts.
- **Solidity** – The primary programming language for smart contract development, ensuring secure and efficient implementation.
- **Networks** – Deployment and testing take place on Sepolia and Holesky testnets, ensuring robustness before mainnet deployment.

## Team
- **@Khemmie-Ray**
- **@theFirstElder**