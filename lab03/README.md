# TokenGold — Signature-Based Approval (Lab03)

## Overview

This project implements an ERC20 token with signature-based approval (permit).

Users can:
- Sign approval messages off-chain
- Let others submit the signature on-chain
- Avoid paying gas for approvals

---

## Tech Stack

- Solidity: 0.8.33
- Framework: Foundry
- Library: OpenZeppelin (ERC20, ECDSA)

---

## Features

- Standard ERC20 (transfer, approve, transferFrom)
- permit() for off-chain approval
- Signature verification using ECDSA
- Nonce tracking (prevents replay attack)
- Deadline (prevents expired signatures)

---

## Setup
```
git clone https://github.com/rango-cmd/bdaf-2026.git
cd bdaf-2026/lab01
forge install
forge build
```
---

## Run Tests
```
forge test -vvv
```
---

## Test Coverage

- Valid permit works
- Invalid signature fails
- Replay attack fails (nonce)
- Expired signature fails
- transferFrom works after permit
- transferFrom fails without permit

---

## Contract

- Token: TokenGold
- Supply: 100,000,000 tokens
- Decimals: 18

---

## Key Function
```
function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 nonce,
    uint256 deadline,
    bytes memory signature
)
```
---

## Deployment

- Contract Address: 0x7e1b73997573ccd50ba21aa26de8351d808531fc
- Verification: https://sourcify.dev/serverv2/verify/b5c139b7-ca01-42f1-ba5d-2a78f85532ce

## Required Flow

1. [Alice receives tokens](https://explorer.garfield-testnet.zircuit.com/tx/0xe64a38e9c41878037cbfd03cbc3cc3a7b313d74fae502dbc1c508c24bb11936e)
2. [Bob submits permit](https://explorer.garfield-testnet.zircuit.com/tx/0xaa54ec55ba5afe5fec9acc705f8f7b31cbc66f77f5d0145dcf7e5bba41544057)
3. [Bob calls transferFrom](https://explorer.garfield-testnet.zircuit.com/tx/0x54f0d6bcad95d3877593fdef3a455b0c17dfa35baee877cdaa93f9a0770a8da3)