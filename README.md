# MetaFi - Restaked Liquidity Pool Hook (RLP Hook)

## Overview
MetaFi is a cross-chain Uniswap v4 hook that enables Liquidity Providers (LPs) to restake their LP positions via EigenLayer. By doing so, LPs contribute to securing Actively Validated Services (AVSs) such as price oracles and rollup sequencers while earning additional EigenLayer rewards. This innovation enhances capital efficiency by transforming idle LP tokens into an active security mechanism.

## Benefits
- **Dual Yield:** LPs benefit from both swap fees and EigenLayer staking rewards.
- **Enhanced Security:** EigenLayer AVSs gain deeper liquidity and stronger security from restaked LP positions.
- **Capital Efficiency:** Instead of LP tokens sitting idle, they are put to work securing decentralized infrastructure.

## How It Works
1. **Liquidity Provision:** Users deposit liquidity into a Uniswap v4 pool.
2. **Restaking Mechanism:** Instead of leaving LP tokens idle, they are restaked via EigenLayer.
3. **AVS Security Contribution:** The restaked LP tokens help secure an Actively Validated Service (AVS) such as:
   - A decentralized price oracle
   - A rollup sequencer
4. **Rewards Distribution:** LPs continue to earn Uniswap swap fees while also receiving EigenLayer restaking rewards.

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