// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DEX {
    using SafeERC20 for IERC20;
    
    address public immutable TOKEN_A;     // x
    address public immutable TOKEN_B;     // y
    uint256 public immutable RATE;        // r
    
    uint256 public reserveA;
    uint256 public reserveB;
    
    uint256 public feeA;
    uint256 public feeB;

    address public immutable FEE_RECIPIENT;

    constructor(
        address _tokenA, 
        address _tokenB,  
        uint256 _rate,
        address _feeRecipient
    ) {
        TOKEN_A = _tokenA;
        TOKEN_B = _tokenB;
        RATE = _rate;
        FEE_RECIPIENT = _feeRecipient;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {

        IERC20(TOKEN_A).safeTransferFrom(msg.sender, address(this), amountA);
        reserveA += amountA;

        IERC20(TOKEN_B).safeTransferFrom(msg.sender, address(this), amountB);
        reserveB += amountB;
    }

    // A + r * B = k
    // fee = 0.1%
    function swap(address tokenIn, uint256 amountIn) external {
        uint256 fee = amountIn / 1000;
        uint256 netAmountIn = amountIn - fee;

        if (tokenIn == TOKEN_A) {
            uint256 amountOut = netAmountIn / RATE;
            
            if (amountOut <= reserveB) {
                IERC20(TOKEN_A).safeTransferFrom(msg.sender, address(this), amountIn);
                feeA += fee;
                reserveA += netAmountIn;
                reserveB -= amountOut;
                IERC20(TOKEN_B).safeTransfer(msg.sender, amountOut);
            } else {
                revert("Insufficient liquidity of TokenB");
            }
        } else if (tokenIn == TOKEN_B) {
            uint256 amountOut = netAmountIn * RATE;
            if (amountOut <= reserveA) {
                IERC20(TOKEN_B).safeTransferFrom(msg.sender, address(this), amountIn);
                feeB += fee;
                reserveB += netAmountIn;
                reserveA -= amountOut;
                IERC20(TOKEN_A).safeTransfer(msg.sender, amountOut);
            } else {
                revert("insufficient liquidity of TokenA");
            }
        } else {
            revert("invalid tokenIn");
        }
    }

    function getReserves() external view returns (uint256 _reserveA, uint256 _reserveB) {
        return (reserveA, reserveB);
    }

    function feeRecipient() external view returns (address) {
        return FEE_RECIPIENT;
    }

    function withdrawFee() external {
        IERC20(TOKEN_A).safeTransfer(FEE_RECIPIENT, feeA);
        IERC20(TOKEN_B).safeTransfer(FEE_RECIPIENT, feeB);
        feeA = 0;
        feeB = 0;
    }
}