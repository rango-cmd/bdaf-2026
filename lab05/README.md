# Upgradeable Proxy Hack & NFT Mint

## Smart Contracts & Scripts

```text
├── script/
│   ├── Deploy.s.sol
│   ├── Stake.s.sol
│   ├── Unstake.s.sol
│   └── UpgradeAndMint.s.sol
└── src/
    ├── MyTokenV1.sol
    └── MyTokenV2.sol
```

## Addresses & Transaction Hashes
* **Deployed ERC20 Proxy Contract:** `0xdb798099093e3f55255a1b11343f5691859cab50`
* **Stake Call Tx Hash:** `0x718f1212b43f4838d0381f6e30dbf5e38c6636ca59e5f89ff30b161060d53383`
* **Unstake Attempt Tx Hash:** `0x224b3d63b16d9aaf7eb757c9de3cbd6c5cffdc09e8e218d42659058826536582`
* **Successful Mint Call Tx Hash (NFT Received):** `0x8e3e3ac9bece012d095fdd24ad6c44058649bcd8a8d74021928e0e2c9279bc45`

## Short Write-Up

### 1. What happened when you called unstake? Did you get your tokens back?
The transaction executed successfully on the blockchain, but it did nothing to my balance. I did not get my tokens back. The function was essentially a trap designed to lock the staked tokens.

### 2. How did you retrieve your tokens?
I didn't actually "retrieve" them to my wallet—I bypassed the trap by destroying the tokens locked in the contract. Because my ERC20 token was deployed behind an upgradeable UUPS proxy, I created a new implementation (`MyTokenV2.sol`) with a custom function. I upgraded my proxy to this V2 implementation, which allowed me to access the internal `_burn()` function and directly burn the target contract's balance down to 0 so the `mint()` requirement would finally pass. 

### 3. What does this teach you about interacting with unverified contracts?
 Never trust a smart contract based purely on function names, ABIs, or assumed behavior. Just because a function is named `unstake()` does not mean it contains the logic to actually unstake anything. If the source code is unverified, you are flying blind, and the contract could do nothing—or be actively malicious. You must always be able to read and verify the source code before granting token approvals or transferring assets.