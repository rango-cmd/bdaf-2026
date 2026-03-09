# Lab02 --- Peer to Peer Token Trade

## Description

This project implements a peer-to-peer ERC20 token trading smart
contract using **Foundry**.

Contracts:

-   TokenA --- ERC20 token
-   TokenB --- ERC20 token
-   TokenTrade --- allows users to create and settle token trades

Users can create a trade with an expiry time. Another user can fulfill
the trade before it expires. Each trade charges a **0.1% fee** which can
be withdrawn by the contract owner.

------------------------------------------------------------------------

## Solidity Version

0.8.33

------------------------------------------------------------------------

## Framework

Foundry

------------------------------------------------------------------------

## Setup

Clone the repository:

    git clone https://github.com/rango-cmd/bdaf-2026.git
    cd bdaf-2026/lab02

Build contracts:

    forge build

------------------------------------------------------------------------

## Run Tests

    forge test

------------------------------------------------------------------------

## Test Coverage

The tests verify the following behaviors:

-   Setup trade successfully
-   Emit event when trade is created
-   Settle trade successfully
-   Emit event when trade is settled
-   Prevent settlement of expired trades
-   Correct token transfers between seller and buyer
-   Correct **0.1% fee deduction**
-   Owner can withdraw accumulated fees
-   Non-owner cannot withdraw fees

All tests should pass.

------------------------------------------------------------------------

## Deployed Contracts (Zircuit Testnet)

[TokenA](https://sourcify.dev/serverv2/verify/a73809fa-33ae-4e0c-b29c-ccc201489575)

    0xdf85d4a9dda592e4850662ad0490f225336f1b7d

[TokenB](https://sourcify.dev/serverv2/verify/5e67d497-2780-4a13-8358-af15578eb4da)

    0xd40fa32cf9189e3633fb705530b2fca75ff3d467

[TokenTrade](https://sourcify.dev/serverv2/verify/10e8fc4f-2d0c-4437-a70d-34a7428c1f0d)

    0xdb798099093e3f55255a1b11343f5691859cab50

------------------------------------------------------------------------

## Example Transactions

Alice setup trade

    0x160fdf2b80d8e83862379d879d68639015419299c1cf02aa0e057c51aea4ecf6

Bob settle trade

    0x9c1bdd83f0d0ebfd211525c5942257f9f64023a900a28be453aa4525e456da47

Owner withdraw fee

    0xa8bcb5ebaa01077b90c27b297f8c94a8660fb2f8ca6dbd86f4ac92b5a3313381
