# PixelForge Gaming Platform

A comprehensive Stacks-based gaming ecosystem that enables game developers to build engaging experiences with collectible NFTs, milestone achievements, and competitive leaderboards.

## Overview

PixelForge provides a decentralized gaming platform where:
- **Game Publishers** can register titles and create collectible NFTs
- **Gamers** can create profiles, compete on leaderboards, and collect rare items
- **Platform** manages achievements, rewards, and cross-game progression

## Core Features

### 🎮 Game Title Management
- Register new game titles on the blockchain
- Publisher-controlled collectible creation
- Active/inactive title status management

### 👤 Gamer Profiles
- Unique handle registration
- Lifetime points accumulation
- Cross-platform progression tracking
- Collectibles inventory management

### 🏆 Competitive Leaderboards
- Per-game high score tracking
- Session count monitoring
- Real-time score submissions

### 💎 Collectible NFTs
- Tiered rarity system (Common, Rare, Epic, Legendary)
- Limited supply mechanics
- STX-based marketplace transactions

### 🎯 Milestone System
- Achievement-based rewards
- STX bonus distributions
- Cross-game milestone tracking

## Smart Contract Structure

### Data Maps
- `game-titles`: Registered games and metadata
- `gamer-accounts`: Player profiles and statistics
- `title-collectibles`: NFT definitions and supply info
- `gamer-inventory`: Player-owned collectibles
- `title-leaderboards`: High scores and play statistics
- `milestone-definitions`: Achievement requirements
- `gamer-milestones`: Player achievement status

### Key Functions

#### For Game Publishers
```clarity
(register-title "Game Name")
(mint-collectible title-id "Collectible Name" "Rare" cost supply)
```

#### For Gamers
```clarity
(create-gamer-account "PlayerHandle")
(record-score title-id score)
(acquire-collectible collectible-id)
```

#### For Platform Admin
```clarity
(grant-milestone gamer milestone-id)
```

## Getting Started

### Prerequisites
- Stacks wallet (Hiro Wallet, Xverse, etc.)
- STX tokens for transactions
- Compatible with Stacks 2.0+ blockchain

### Deployment
1. Deploy the contract to Stacks testnet/mainnet
2. The deployer automatically becomes the platform admin
3. Configure ecosystem fee percentage (default: 3.0%)

### For Developers
1. Contact platform admin to register your game title
2. Create collectibles with appropriate pricing and supply limits
3. Integrate score submission into your game client

### For Players
1. Create a gamer account with unique handle
2. Play registered games and submit scores
3. Purchase collectibles using STX
4. Earn milestones and receive bonus rewards

## Economic Model

- **Platform Fee**: 3.0% of all collectible sales
- **Collectible Pricing**: Set by individual game publishers
- **Milestone Rewards**: Distributed in STX by platform admin
- **Gas Fees**: Standard Stacks transaction costs apply

## Security Features

- Owner-only functions for critical operations
- Supply limits prevent infinite minting
- Duplicate prevention for accounts and achievements
- Balance verification before transactions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit pull request with comprehensive tests
4. Ensure compliance with Stacks best practices
