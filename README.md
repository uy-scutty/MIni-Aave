# 🏦 MyMiniAave

A minimal decentralized lending protocol inspired by Aave.

MyMiniAave allows users to:

- Deposit ERC20 assets
- Receive interest-bearing aTokens
- Borrow against collateral
- Repay debt
- Withdraw liquidity safely

Built for learning and understanding core DeFi lending mechanics.

---

# ⚙️ Core Features

### 💰 Multi-Asset Lending Pools

Each supported token has its own reserve with isolated accounting.

### 🪙 Collateral System

Users deposit assets which act as collateral for borrowing.

### 📉 Borrowing with LTV Protection

Borrowing is limited by Loan-To-Value (LTV) per asset.

### 🔁 Debt Tracking

Debt is tracked using separate DebtTokens per asset.

### 💸 Liquidity Management

Ensures withdrawals and borrows are limited by available pool liquidity.

### 🛡️ Security

- Reentrancy protection (ReentrancyGuard)
- Safe ERC20 transfers (SafeERC20)

---

# 🧠 Key Concepts

## Reserve

Each asset has a reserve that tracks:

- Total deposits
- Total borrowed amount
- LTV ratio
- Token contracts (aToken + debtToken)

## Collateral

User deposits are tracked per asset and used to determine borrowing power.

## LTV (Loan-To-Value)

Defines how much a user can borrow based on their collateral.

---

# 🏗️ Architecture

User  
→ MyMiniAave (Core Contract)  
→ Reserve (per asset)  
→ aToken (deposit receipt)  
→ debtToken (borrowed debt)

---

# 🔁 User Flows

## Deposit

- User deposits ERC20 token
- Reserve updates liquidity
- User receives aTokens

## Borrow

- Collateral is checked
- LTV is enforced
- Liquidity is checked
- Asset is transferred to user
- Debt tokens are minted

## Repay

- User repays debt
- Debt tokens are burned
- Reserve updates debt

## Withdraw

- User withdraws collateral
- Liquidity is checked
- aTokens are burned
- Asset is returned

---

# 🔐 Security Features

- Reentrancy protection
- SafeERC20 transfers
- Reserve initialization checks
- LTV enforcement
- Liquidity validation

---

# 🚧 Limitations

This is a minimal DeFi prototype and does NOT include:

- Price oracles
- Liquidation system
- Health factor
- Interest rate model
- Governance system

---

# 📌 Future Improvements

- Chainlink price oracle integration
- Health factor + liquidation engine
- Dynamic interest rates
- Multi-collateral borrowing
- Asset whitelist / admin control

---

# 🎯 Purpose

This project is built to understand how lending protocols work internally — liquidity, collateral, and debt mechanics.

---

# 🧠 Inspired By

- Aave
- Compound Finance
- Modern DeFi lending systems
