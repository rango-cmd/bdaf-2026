# BDaF 2026 Lab04 — Membership Board

## Overview

This project implements a Membership Board to compare three different approaches for managing 1,000 members on-chain: single-entry mapping, batch-entry mapping, and Merkle Tree commitments.

## Setup & Execution

### Prerequisites

- [Foundry](https://www.getfoundry.sh/) installed.
- JavaScript library `@openzeppelin/merkle-tree` and `ethers` installed. 
- `members.json` and `merkle-data.json` must be present in the root directory.

### Project Structure


### Commands
```bash
git clone https://github.com/rango-cmd/bdaf-2026.git
cd bdaf-2026/lab04

forge build
# Test All Cases
forge test -vv
# Test Gas Profiling
forge test --match-test test_gas_Measurements --gas-report -vv
```

### Gas Profiling Results

| Action | Gas Used |
|:-------|--------:|
| `addMember` (single call) | 46,463 |
| `addMember` x 1,000 (total estimated) | 46,463,000 |
| `batchAddMembers` size 50 (single call) | 1,297,977 |
| `batchAddMembers` size 100 (single call) | 2,569,065 |
| `batchAddMembers` size 200 (single call) | 5,111,145 |
| `batchAddMembers` size 500 (single call) | 12,737,397 |
| `batchAddMembers` size 1,000 | 25,447,845 |
| `setMerkleRoot` | 46,183 |
| `verifyMemberByMapping` | 3,888 |
| `verifyMemberByProof` | 10,937 |

## Questions & Analysis

1. **Storage cost comparison:** 

    **Result:**
    
    `addMember` > `batchAddMembers` > `setMerkleRoot`
    
    **Why:**
    
    `setMerkleRoot` only updates a single bytes32 slot regardless of the list size. Mapping approaches require `SSTORE` for every member ($20,000$ gas per new slot), leading to massive costs for 1,000 entries.

2. **Verification cost comparison:**

    **Result:**
    
    `verifyMemberByProof` > `verifyMemberByMapping`
    
    **Why:**
    
    Mapping is a direct `SLOAD` operation. Merkle verification requires multiple `keccak256` hashes (proportional to the tree height, $\log_2(1000) \approx 10$ iterations) and additional calldata for the proof.

3. **Trade-off analysis:**

    **Prefer Mapping:**
    
    The list changes frequently (dynamic), the member list is small, or you want the lowest possible cost for the user (the verifier).
    
    **Prefer Merkle Tree:**
    
    The list is very large, the list is static or changes in "epochs," or you want the lowest possible cost for the admin (the storer).
    
    **Privacy:**
    
    Merkle Trees allow for private lists where users only know their own proof; mappings are fully transparent on-chain.

4. **Batch size experimentation:**

    As the batch size increases, the per-member gas cost decreases because the fixed transaction overhead (21,000 gas) and the function signature overhead are spread across more entries.
    
    - **Small batches (50):** Higher overhead per member.
    - **Large batches (500+):** Most efficient, but risks hitting the Block Gas Limit (60,000,000 Gas).