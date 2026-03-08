// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

// Import OpenZeppelin ERC20 implementation
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title TokenA
/// @notice Simple ERC20 token used for trading in the TokenTrade contract
contract TokenA is ERC20 {

    // Initial supply = 100,000,000 tokens (18 decimals)
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 1e18;

    /// @notice Mint the full supply to the deployer
    constructor() ERC20("AlphaToken", "ALP") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}
