# Mini Aave

A simplified Aave-inspired lending protocol built in Solidity that enables users to deposit collateral, borrow assets, repay debt, withdraw collateral, and liquidate unhealthy positions.

The protocol uses Chainlink Price Feeds for asset valuation and implements a risk management system based on Loan-to-Value (LTV), liquidation thresholds, and health factors.

---

## Overview

Mini Aave is a decentralized lending protocol designed to explore the core mechanics behind modern DeFi lending markets.

Users can:

- Deposit supported assets as collateral
- Borrow against deposited collateral
- Repay borrowed assets
- Withdraw collateral
- Liquidate undercollateralized positions

The protocol tracks collateral and debt positions across multiple assets and uses oracle pricing to determine borrowing power and liquidation eligibility.

---

## Features

### Lending

Users can deposit supported assets into the protocol as collateral.

Deposits:
- Increase protocol liquidity
- Increase borrowing power
- Mint aTokens to represent supplied assets

### Borrowing

Users can borrow assets against their collateral.

Borrow limits are determined by:

- Collateral value
- Asset LTV configuration
- Existing debt

### Repayment

Borrowers can repay debt partially or fully.

Debt repayment:
- Reduces outstanding debt
- Burns DebtTokens

### Withdrawals

Users can withdraw collateral provided their position remains healthy after withdrawal.

### Liquidations

When a user's Health Factor falls below 1, their position becomes eligible for liquidation.

Liquidators:
- Repay part of the user's debt
- Receive collateral at a discount through the liquidation bonus mechanism

### Oracle-Based Pricing

The protocol integrates Chainlink Price Feeds to determine:

- Collateral value
- Debt value
- Borrow limits
- Health factors
- Liquidation amounts

---

# Architecture

The system consists of three core components:

## MyMiniAave

The core lending protocol.

Responsibilities:

- Deposits
- Withdrawals
- Borrowing
- Repayments
- Liquidations
- Reserve management
- Health factor calculations
- Oracle integrations

---

## AToken

Interest-bearing token minted when users deposit collateral.

Represents ownership of deposited assets inside the protocol.

Example:

Deposit 100 USDC

↓

Receive 100 aUSDC

---

## DebtToken

Debt representation token minted when users borrow assets.

Represents outstanding debt owed to the protocol.

Example:

Borrow 50 USDC

↓

Receive 50 dUSDC

---

# Reserve System

Each supported asset is represented by a Reserve.

A reserve stores:

- Total deposited liquidity
- Total borrowed liquidity
- AToken address
- DebtToken address
- Loan-To-Value ratio
- Liquidation threshold
- Liquidation bonus
- Chainlink price feed

Only the protocol owner can initialize new reserves.

---

# Oracle Integration

The protocol uses Chainlink AggregatorV3 price feeds.

Each reserve is configured with a dedicated price feed.

Prices are normalized to 18 decimals before being used throughout the protocol.

Oracle prices are used for:

- Collateral valuation
- Debt valuation
- Borrow limit calculations
- Health factor calculations
- Liquidation calculations

---

# Borrowing Model

The maximum amount a user can borrow is determined by:

Maximum Borrow Value =
Collateral Value × LTV

Example:

Collateral Value = $1,000

LTV = 75%

Maximum Borrow = $750

---

# Health Factor

The Health Factor determines whether a position is healthy.

Formula:

Health Factor =
Adjusted Collateral Value / Total Debt Value

Where:

Adjusted Collateral Value =
Collateral Value × Liquidation Threshold

Example:

Collateral Value = $1,000

Liquidation Threshold = 80%

Adjusted Collateral = $800

Debt = $500

Health Factor = 1.6

Position is healthy.

---

## Liquidation Condition

A position becomes liquidatable when:

Health Factor < 1

At this point, a liquidator can repay debt and seize collateral.

---

# Liquidation Flow

When a user becomes undercollateralized:

1. Liquidator repays debt
2. Debt value is converted to USD
3. Liquidation bonus is applied
4. Equivalent collateral is calculated
5. Collateral is transferred to the liquidator

The protocol uses oracle prices to correctly value debt and collateral assets even when they are different assets.

---

# Security Features

Current protections include:

- ReentrancyGuard
- SafeERC20
- Reserve validation
- Oracle validation
- Borrow limit enforcement
- Health factor checks
- Liquidation eligibility checks

---

# Contract Functions

## User Functions

### deposit()

Supply collateral to the protocol.

### withdraw()

Withdraw collateral if position remains healthy.

### borrow()

Borrow assets against collateral.

### repay()

Repay borrowed assets.

### liquidate()

Liquidate unhealthy positions.

---

## View Functions

### getAssetPrice()

Returns normalized Chainlink price.

### getUserAssetValue()

Returns USD value of a user's collateral asset.

### getTotalCollateral()

Returns total collateral value.

### getTotalDebt()

Returns total debt value.

### calculateHealthFactor()

Returns user's current health factor.

### isLiquidatable()

Returns liquidation status.

---

## Admin Functions

### initReserve()

Creates a new reserve and configures:

- aToken
- debtToken
- LTV
- liquidation threshold
- liquidation bonus
- price feed

---

# Installation

Clone repository:

```bash
git clone <repo-url>
```

Install dependencies:

```bash
forge install
```

Build:

```bash
forge build
```

Run tests:

```bash
forge test -vvv
```

Generate coverage:

```bash
forge coverage
```

# Tech Stack

- Solidity
- Foundry
- OpenZeppelin Contracts
- Chainlink Price Feeds

# Future Improvements

Planned upgrades:

- Dynamic interest rate model
- Interest accrual
- Flash loans
- Governance system
- Reserve pause functionality
- Oracle staleness checks
- Advanced risk engine
- Frontend dashboard
- Automated liquidation network

# Learning Goals

This project was built to deepen understanding of:

- DeFi lending protocols
- Risk management systems
- Oracle integrations
- Liquidation mechanisms
- Collateralized debt positions
- Smart contract architecture
- Protocol design

# Disclaimer

This project is for educational and research purposes only.

It has not been audited and should not be used in production environments with real funds.
