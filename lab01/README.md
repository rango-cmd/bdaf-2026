# EthVault -- Lab01

## Project Description

EthVault is a minimal ETH vault smart contract written in Solidity.

The contract allows users to send ETH to it and allows only the contract
OWNER (the deployer) to withdraw funds.\
It includes event logging, custom errors, and reentrancy protection.

------------------------------------------------------------------------

## Solidity Version

0.8.33

------------------------------------------------------------------------

## Framework Used

-   Foundry
-   forge-std (for testing utilities)

------------------------------------------------------------------------

## Project Structure
```
lab01/
├── src/
│    └── EthVault.sol
├── test/
│    └── EthVault.t.sol
└── README.md
```
------------------------------------------------------------------------

## Setup Instructions

Install Foundry (if not installed):

    curl -L https://foundry.paradigm.xyz | bash
    foundryup

Build the project:

    forge build

------------------------------------------------------------------------

## Test Instructions

Run all tests:

    forge test

Run with verbose logs:

    forge test -vvv

Run with gas report:

    forge test --gas-report

------------------------------------------------------------------------

## Test Coverage Details

### Group A -- Deposits

These tests verify ETH reception behavior:

-   Single deposit
    -   ETH can be sent to the contract
    -   Deposit event is emitted correctly
    -   Contract balance increases properly
-   Multiple deposits (same sender)
    -   Multiple transactions increase balance cumulatively
    -   Each Deposit event is emitted correctly
-   Deposits from different senders
    -   ETH from multiple addresses is accepted
    -   Events reflect correct sender
    -   Total balance equals sum of deposits

------------------------------------------------------------------------

### Group B -- Owner Withdrawal

These tests verify correct withdrawal behavior by the owner:

-   Partial withdrawal
    -   Owner can withdraw part of balance
    -   Weethdraw event is emitted
    -   Contract balance decreases correctly
    -   Owner balance increases correctly
-   Full withdrawal
    -   Owner can withdraw entire balance
    -   Contract balance becomes zero
    -   Event emitted correctly

------------------------------------------------------------------------

### Group C -- Unauthorized Withdrawal

These tests verify non-owner behavior:

-   Non-owner withdraw attempt
    -   Transaction does NOT revert
    -   UnauthorizedWithdrawAttempt event emitted
    -   Contract balance remains unchanged

------------------------------------------------------------------------

### Group D -- Edge Cases

-   Withdraw more than balance
    -   Reverts with InsufficientBalance error
-   Withdraw zero
    -   Succeeds without changing balance
    -   Event emitted correctly
-   Multiple deposits before withdrawal
    -   Balance aggregates correctly
    -   Withdrawal reduces correct amount

------------------------------------------------------------------------

### Group E -- Reentrancy Protection

A malicious contract is used to simulate a reentrancy attack:

-   During withdraw, attacker attempts to call withdraw again
-   Reentrancy guard blocks the second call
-   Reentrancy error is triggered
-   Only the original withdrawal succeeds
-   Vault balance decreases exactly once
