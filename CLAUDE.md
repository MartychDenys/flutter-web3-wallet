# 🧠 CLAUDE.md — Flutter Web3 Wallet (Sepolia)

## 🎯 Project Overview

This project is a **Flutter-based Ethereum wallet** built with:

* **Clean Architecture**
* **Riverpod (AsyncNotifier)**
* **web3dart**
* Network: **Sepolia Testnet**

---

## 🚀 Features Implemented

### ✅ Core

* Get wallet balance (ETH)
* Send transaction (ETH)
* Sign transaction (raw TX)
* Simulate transaction (without broadcasting)
* Estimate gas fee
* Calculate max sendable amount

### ✅ UX

* Debounced input
* Loading / error states
* Validation before sending
* "MAX" button
* Separate simulate button

---

## 🏗️ Architecture

### 🔹 Layers

```text
presentation/
domain/
data/
core/web3/
```

---

### 🔹 Data Flow

```text
UI → AsyncNotifier → UseCase → Repository → DataSource → Web3Service
```

---

## ⚙️ State Management (Riverpod)

### 🔥 Why AsyncNotifier

Used because:

* Handles async operations (network/web3)
* Provides loading / error / data states
* Keeps business logic out of UI

---

### 🔹 Main Providers

```dart
final addressInputProvider
final submittedAddressProvider
final balanceProvider
final gasFeeProvider
final sendTxNotifierProvider
```

---

## 💸 Balance

### Use Case

```dart
getBalance(address)
```

### Implementation

```dart
client.getBalance(address)
```

---

## ⛽ Gas Handling

### ⚠️ Known Issue

```text
estimateGas fails if balance = 0
```

---

### ✅ Solution

For simple ETH transfer:

```dart
const gasLimit = 21000;
final gasPrice = await client.getGasPrice();

final fee = gasPrice * BigInt.from(gasLimit);
```

---

### 🧠 Insight

```text
ETH transfer → fixed gas (21000)
Smart contract → dynamic (estimateGas)
```

---

## 🔐 Transaction Signing

### Flow

```text
privateKey → credentials → signTransaction → raw tx
```

---

### ⚠️ Common Error

```text
Uint8List != String
```

### ✅ Fix

```dart
bytesToHex(signedTx, include0x: true)
```

---

## 🚀 Sending Transaction

### Flow

```text
sign → sendRawTransaction
```

---

### ❌ Error

```text
insufficient funds for gas + value
```

### 🧠 Cause

```text
balance == 0
```

---

## 🧪 Simulate Transaction

### What it is

```text
signTransaction without sending
```

---

### Purpose

* Debugging
* Preview TX
* UX improvement

---

## 🧾 Nonce

```text
Number of transactions sent from an address
```

### Usage

```dart
client.getTransactionCount(address)
```

---

## 🔑 Private Key

### 🧠 Important

```text
1 account = 1 private key (shared across networks)
```

---

### MetaMask Notes

* May not expose private key directly
* Accessible via:

    * Export Private Key
    * Secret Recovery Phrase (seed)

---

## 🌐 Network

```text
Sepolia Testnet
chainId = 11155111
```

---

## ❗ Common Errors & Fixes

### 1. Invalid Address

```text
Missing 0x prefix
```

---

### 2. BigInt Parse Error

```text
FormatException: BigInt.parse("1.0")
```

### ✅ Fix

```dart
EtherAmount.fromUnitAndValue(EtherUnit.ether, amount)
```

---

### 3. Gas Estimation Crash

```text
estimateGas fails without funds
```

---

### 4. Gas Not Showing

Cause:

```text
Depends on submittedAddress instead of live input
```

Fix:

```text
Use direct address input
```

---

## 📱 UI Logic

### 🔐 Validation

Disable send if:

```text
- privateKey is empty
- toAddress is empty
- amount <= 0
```

---

### 🔁 Debounce

Used for address input to reduce unnecessary calls.

---

## 🔝 Max Send Logic

```text
max = balance - fee
```

---

## 🧠 Clean Architecture Rules

### ❌ Avoid

```text
UI → Web3 directly
```

---

### ✅ Correct

```text
UI → UseCase → Repository → DataSource → Web3
```

---

## 🧠 Key Learnings

* Web3 transaction lifecycle
* Gas mechanics
* Nonce handling
* Signing transactions
* Riverpod async state management
* Wallet UX patterns

---

## 🚀 Next Steps

### 🔹 Level 2

* ERC20 token transfers
* Token balance support
* Transaction history

---

### 🔹 Level 3

* WalletConnect integration
* dApp browser
* Multi-chain support

---

## 🧾 Notes

This project represents a **near-production-level wallet foundation**, covering:

* Core blockchain interactions
* Proper architecture
* Scalable state management

---

## 💬 Usage Tip for Claude

You can use this document to:

* Generate new features
* Refactor architecture
* Add tests
* Improve UX
* Extend to multi-chain

---
