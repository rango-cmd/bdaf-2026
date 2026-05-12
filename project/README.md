# TRON Behavioral Analysis

## Project Goal

To identify and categorize TRON addresses based on on-chain behavior. The system aims to:

- Classify addresses (e.g., Exchange, Bot, Scam, Personal).
- **Cluster related addresses** that share behavioral patterns, even in the absence of direct transaction links.

## Data Sources (Labels)

Used for model training and validation:

- Law Enforcement: Known illicit addresses and sanctioned entities.
- Open Source: Publicly available labels from TRONSCAN, Arkham, and GitHub repositories.

## Analysis Vectors (Features)

We analyze the following dimensions to build a "behavioral fingerprint":

- Lifetime: Duration between the first and most recent activity.
- Token Velocity: Frequency and volume of TRC-20 transfers (specifically stable coin).
- Transaction Profile:
- Counterparty Graph: Analysis of the neighborhood (but how deep?)
