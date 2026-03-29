// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenB is ERC20 {
    
    uint256 public constant INITIAL_SUPPLY = 100_000 * 1e18;

    constructor() ERC20("TokenB", "TKB") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}