# Flutter Web3 Wallet

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Solidity](https://img.shields.io/badge/Solidity-0.8.24-363636?logo=solidity)
![Network](https://img.shields.io/badge/Network-Sepolia_Testnet-6f3ff5)
![Architecture](https://img.shields.io/badge/Architecture-Clean-brightgreen)
![State](https://img.shields.io/badge/State-Riverpod-blue)

A production-quality Ethereum wallet built with Flutter + Riverpod, targeting the Sepolia testnet. Covers the full Web3 stack: raw ETH transfers, ERC20/ERC721 tokens, WalletConnect v2, HD wallet derivation, two custom Solidity contracts deployed and verified on-chain, and a token-powered merch shop.

---

## Features

### Wallet
- Check ETH balance by address or ENS name (e.g. `vitalik.eth`)
- Send ETH with live gas fee estimation
- MAX button (balance − gas)
- Simulate transaction (sign without broadcasting)
- Live USD price via CoinGecko

### ERC20 Tokens
- Balances for any ERC20 contract (USDC, LINK, WETH, custom)
- Token transfer UI
- Add custom contract by address

### NFTs (ERC721)
- Owned NFT grid via Etherscan API
- IPFS metadata resolution (`ipfs://` → HTTPS gateway)
- NFT detail with attributes and transfer

### Transaction History
- Full ETH + ERC20 history via Etherscan API
- Direction detection (incoming / outgoing / self)
- Gas fee calculation
- Detail screen with copy + Etherscan link

### WalletConnect v2
- Pair via URI or QR code scan
- Approve / reject session proposals
- Handle `personal_sign` and `eth_sendTransaction` requests
- Active sessions list

### HD Wallet (BIP39 / BIP44)
- Generate 12-word mnemonic phrase
- Import existing mnemonic
- Derive multiple accounts (`m/44'/60'/0'/0/n`)
- Show / hide mnemonic words

### My Contracts
- **DevToken (ERC20)** — custom ERC20, deployed & verified on Sepolia
- **DevNFT (ERC721)** — custom ERC721, deployed & verified on Sepolia
- Check DEV token balance and total NFT supply
- Transfer DEV tokens
- Mint DevNFT (owner-only)

### Battle Toads Shop 🐸
A token-powered merch shop built on top of the wallet:
- **Mine TOADS** — accumulate tokens over time with a mining mechanic
- **Shop** — spend TOADS on real branded merchandise (T-shirts, caps)
- **Accessories gallery** — swipeable PageView with 4 cap variants
- **Shipping form** — name, city, Nova Poshta address
- **My Orders** — order history with Processing → Shipped → Delivered status stepper
- Badge on "My Orders" showing count of open orders

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | Flutter + Material 3 |
| State | Riverpod (StateNotifier, AsyncNotifier, FutureProvider) |
| Web3 | web3dart |
| WalletConnect | walletconnect_flutter_v2 |
| HD Wallet | bip39 + bip32 |
| Blockchain API | Etherscan v2 API |
| Prices | CoinGecko API |
| ENS | Ethereum Name Service resolution |
| Storage | SharedPreferences |
| Architecture | Clean Architecture (presentation / domain / data / core) |
| Network | Sepolia Testnet (chainId 11155111) |

---

## Architecture

```
lib/
├── core/
│   ├── web3/          # Web3Service (ETH, ERC20, ERC721)
│   ├── walletconnect/ # WalletConnect v2 service
│   ├── hd_wallet/     # BIP39/BIP44 derivation
│   ├── contracts/     # Deployed contract addresses
│   ├── ens/           # ENS name resolution
│   ├── price/         # CoinGecko price provider
│   └── theme/         # App theme (dark, neon green)
└── features/
    ├── wallet/        # ETH balance + send
    ├── tokens/        # ERC20 list + transfer
    ├── nft/           # ERC721 grid + detail
    ├── transactions/  # History
    ├── walletconnect/ # WC session management
    ├── hd_wallet/     # Mnemonic + accounts
    ├── my_contracts/  # DevToken + DevNFT UI
    └── toss/          # Battle Toads Shop (mining + merch)
```

Data flow: `UI → Notifier → UseCase → Repository → DataSource → Web3Service`

---

## Deployed Contracts (Sepolia)

| Contract | Address | Etherscan |
|---|---|---|
| DevToken (ERC20) | `0xC1E306114F040c509CfEA260ad1dC0cCAE807e57` | [View ↗](https://sepolia.etherscan.io/address/0xC1E306114F040c509CfEA260ad1dC0cCAE807e57#code) |
| DevNFT (ERC721) | `0xc6EAE7b4FEab46d2645EDd8Fff53F36E8937c5D4` | [View ↗](https://sepolia.etherscan.io/address/0xc6EAE7b4FEab46d2645EDd8Fff53F36E8937c5D4#code) |

Solidity source: [MartychDenys/web3-contracts](https://github.com/MartychDenys/web3-contracts)

---

## Setup

```bash
git clone https://github.com/MartychDenys/flutter-web3-wallet.git
cd flutter-web3-wallet
flutter pub get
flutter run
```

> Add your own API keys in:
> - `lib/core/web3/web3_service.dart` — Infura/Alchemy RPC URL
> - `lib/features/transactions/data/data_sources/etherscan_data_source.dart` — Etherscan API key

---

## What I learned

- Full Web3 transaction lifecycle (nonce, gas, signing, broadcasting)
- ERC20 and ERC721 standards from the Solidity spec
- WalletConnect v2 protocol (session proposals, JSON-RPC requests)
- BIP39 mnemonic generation and BIP44 hierarchical key derivation
- Writing Solidity contracts from scratch with custom errors and events
- Deploying and verifying contracts on a public testnet
- ENS name resolution on-chain
- Building a token economy (mine → earn → spend) on top of a wallet
