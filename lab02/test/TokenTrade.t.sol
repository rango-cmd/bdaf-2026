// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {TokenA} from "../src/TokenA.sol";
import {TokenB} from "../src/TokenB.sol";
import {TokenTrade} from "../src/TokenTrade.sol";

contract TokenTradeTest is Test {

    TokenA internal tokenA;
    TokenB internal tokenB;
    TokenTrade internal tokenTrade;

    address internal seller = makeAddr("seller");
    address internal buyer = makeAddr("buyer");
    address internal other = makeAddr("other");

    uint256 internal constant SELL_AMOUNT = 100 ether;
    uint256 internal constant ASK_AMOUNT = 200 ether;
    uint256 internal constant FEE = ASK_AMOUNT / 1000; // 0.1%

    /// @notice Deploy TokenA, TokenB, and TokenTrade before each test
    /// @dev Also distributes tokens to seller and buyer accounts
    /// so they can simulate real trading interactions.
    function setUp() public {
        tokenA = new TokenA();
        tokenB = new TokenB();
        tokenTrade = new TokenTrade(address(tokenA), address(tokenB));

        tokenA.transfer(seller, 1_000 ether);
        tokenB.transfer(buyer, 1_000 ether);
    }
    
    /// @notice Test successful creation of a trade
    /// @dev Verifies that:
    /// - seller deposits tokens into the contract
    /// - trade data is stored correctly
    /// - contract balance increases
    /// - seller balance decreases accordingly
    function test_SetupTrade_Works() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.startPrank(seller);
        tokenA.approve(address(tokenTrade), SELL_AMOUNT);
        tokenTrade.setupTrade(address(tokenA), SELL_AMOUNT, ASK_AMOUNT, expiry);
        vm.stopPrank();

        (
            address recordedSeller,
            address inputToken,
            uint256 inputAmount,
            uint256 outputAsk,
            uint256 recordedExpiry,
            bool settled,
            bool cancelled
        ) = tokenTrade.trades(0);

        assertEq(recordedSeller, seller);
        assertEq(inputToken, address(tokenA));
        assertEq(inputAmount, SELL_AMOUNT);
        assertEq(outputAsk, ASK_AMOUNT);
        assertEq(recordedExpiry, expiry);
        assertEq(settled, false);
        assertEq(cancelled, false);

        assertEq(tokenA.balanceOf(address(tokenTrade)), SELL_AMOUNT);
        assertEq(tokenA.balanceOf(seller), 900 ether);
    }
    
    /// @notice Test successful settlement of a trade
    /// @dev Verifies that:
    /// - buyer receives seller's deposited tokens
    /// - seller receives payment minus protocol fee
    /// - protocol fee is recorded correctly
    /// - trade state is marked as settled
    function test_SettleTrade_Works() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.startPrank(seller);
        tokenA.approve(address(tokenTrade), SELL_AMOUNT);
        tokenTrade.setupTrade(address(tokenA), SELL_AMOUNT, ASK_AMOUNT, expiry);
        vm.stopPrank();

        vm.startPrank(buyer);
        tokenB.approve(address(tokenTrade), ASK_AMOUNT);
        tokenTrade.settleTrade(0);
        vm.stopPrank();

        assertEq(tokenA.balanceOf(buyer), SELL_AMOUNT);
        assertEq(tokenB.balanceOf(seller), ASK_AMOUNT - FEE);
        assertEq(tokenTrade.accumulatedFees(address(tokenB)), FEE);

        (, , , , , bool settled, bool cancelled) = tokenTrade.trades(0);
        assertTrue(settled);
        assertFalse(cancelled);
    }

    /// @notice Ensure a trade cannot be settled after expiration
    /// @dev Simulates time passing using vm.warp and verifies
    /// the contract reverts with TradeExpired
    function test_SettleTrade_RevertIf_Expired() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.startPrank(seller);
        tokenA.approve(address(tokenTrade), SELL_AMOUNT);
        tokenTrade.setupTrade(address(tokenA), SELL_AMOUNT, ASK_AMOUNT, expiry);
        vm.stopPrank();

        vm.warp(expiry + 1);

        vm.startPrank(buyer);
        tokenB.approve(address(tokenTrade), ASK_AMOUNT);
        vm.expectRevert(TokenTrade.TradeExpired.selector);
        tokenTrade.settleTrade(0);
        vm.stopPrank();
    }

    /// @notice Test that seller can cancel an expired trade
    /// @dev Verifies that:
    /// - deposited tokens are returned to the seller
    /// - trade is marked as cancelled
    /// - contract token balance decreases
    function test_CancelExpiredTrade_Works() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.startPrank(seller);
        tokenA.approve(address(tokenTrade), SELL_AMOUNT);
        tokenTrade.setupTrade(address(tokenA), SELL_AMOUNT, ASK_AMOUNT, expiry);
        vm.stopPrank();

        vm.warp(expiry + 1);

        vm.prank(seller);
        tokenTrade.cancelExpiredTrade(0);

        assertEq(tokenA.balanceOf(seller), 1_000 ether);
        assertEq(tokenA.balanceOf(address(tokenTrade)), 0);

        (, , , , , bool settled, bool cancelled) = tokenTrade.trades(0);
        assertFalse(settled);
        assertTrue(cancelled);
    }

    /// @notice Ensure only the seller can cancel an expired trade
    /// @dev Any other address attempting cancellation should revert
    /// with NotSeller
    function test_CancelExpiredTrade_RevertIf_NotSeller() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.startPrank(seller);
        tokenA.approve(address(tokenTrade), SELL_AMOUNT);
        tokenTrade.setupTrade(address(tokenA), SELL_AMOUNT, ASK_AMOUNT, expiry);
        vm.stopPrank();

        vm.warp(expiry + 1);

        vm.prank(other);
        vm.expectRevert(TokenTrade.NotSeller.selector);
        tokenTrade.cancelExpiredTrade(0);
    }

    /// @notice Ensure trade cannot be cancelled before expiration
    /// @dev Contract should revert with TradeNotExpired
    function test_CancelExpiredTrade_RevertIf_NotExpired() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.startPrank(seller);
        tokenA.approve(address(tokenTrade), SELL_AMOUNT);
        tokenTrade.setupTrade(address(tokenA), SELL_AMOUNT, ASK_AMOUNT, expiry);
        vm.stopPrank();

        vm.prank(seller);
        vm.expectRevert(TokenTrade.TradeNotExpired.selector);
        tokenTrade.cancelExpiredTrade(0);
    }

    /// @notice Test protocol fee withdrawal by owner
    /// @dev Verifies that:
    /// - accumulated fees are transferred to the owner
    /// - internal fee balance resets to zero
    function test_WithdrawFee_Works() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.startPrank(seller);
        tokenA.approve(address(tokenTrade), SELL_AMOUNT);
        tokenTrade.setupTrade(address(tokenA), SELL_AMOUNT, ASK_AMOUNT, expiry);
        vm.stopPrank();

        vm.startPrank(buyer);
        tokenB.approve(address(tokenTrade), ASK_AMOUNT);
        tokenTrade.settleTrade(0);
        vm.stopPrank();

        uint256 ownerBalanceBefore = tokenB.balanceOf(address(this));

        tokenTrade.withdrawFee();

        uint256 ownerBalanceAfter = tokenB.balanceOf(address(this));

        assertEq(ownerBalanceAfter - ownerBalanceBefore, FEE);
        assertEq(tokenTrade.accumulatedFees(address(tokenB)), 0);
    }

    /// @notice Ensure only contract owner can withdraw fees
    /// @dev Non-owner call should revert with NotOwner
    function test_WithdrawFee_RevertIf_NotOwner() public {
        vm.prank(other);
        vm.expectRevert(TokenTrade.NotOwner.selector);
        tokenTrade.withdrawFee();
    }

    /// @notice Ensure trades can only use TokenA or TokenB
    /// @dev Passing an unsupported token address should revert
    /// with InvalidToken
    function test_SetupTrade_RevertIf_InvalidToken() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(seller);
        vm.expectRevert(TokenTrade.InvalidToken.selector);
        tokenTrade.setupTrade(other, SELL_AMOUNT, ASK_AMOUNT, expiry);
    }

    /// @notice Ensure trade cannot be created with zero input amount
    /// @dev Contract should revert with InvalidAmount
    function test_SetupTrade_RevertIf_ZeroAmount() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(seller);
        vm.expectRevert(TokenTrade.InvalidAmount.selector);
        tokenTrade.setupTrade(address(tokenA), 0, ASK_AMOUNT, expiry);
    }

    /// @notice Ensure trade cannot request zero output tokens
    /// @dev Contract should revert with InvalidAmount
    function test_SetupTrade_RevertIf_ZeroAsk() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(seller);
        vm.expectRevert(TokenTrade.InvalidAmount.selector);
        tokenTrade.setupTrade(address(tokenA), SELL_AMOUNT, 0, expiry);
    }

    /// @notice Ensure expiry timestamp must be in the future
    /// @dev Expiry equal to or earlier than current block time
    /// should revert with InvalidExpiry
    function test_SetupTrade_RevertIf_InvalidExpiry() public {
        vm.prank(seller);
        vm.expectRevert(TokenTrade.InvalidExpiry.selector);
        tokenTrade.setupTrade(address(tokenA), SELL_AMOUNT, ASK_AMOUNT, block.timestamp);
    }

    /// @notice Ensure settlement fails for non-existent trade IDs
    /// @dev Contract should revert with TradeNotFound
    function test_SettleTrade_RevertIf_TradeNotFound() public {
        vm.prank(buyer);
        vm.expectRevert(TokenTrade.TradeNotFound.selector);
        tokenTrade.settleTrade(999);
    }

    /// @notice Ensure a trade cannot be settled more than once
    /// @dev Second settlement attempt should revert with
    /// TradeAlreadySettled
    function test_SettleTrade_RevertIf_AlreadySettled() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.startPrank(seller);
        tokenA.approve(address(tokenTrade), SELL_AMOUNT);
        tokenTrade.setupTrade(address(tokenA), SELL_AMOUNT, ASK_AMOUNT, expiry);
        vm.stopPrank();

        vm.startPrank(buyer);
        tokenB.approve(address(tokenTrade), ASK_AMOUNT);
        tokenTrade.settleTrade(0);
        vm.expectRevert(TokenTrade.TradeAlreadySettled.selector);
        tokenTrade.settleTrade(0);
        vm.stopPrank();
    }

    /// @notice Verify correct output token for a trade
    /// @dev If seller deposits TokenA, output token should be TokenB
    /// and vice versa
    function test_GetOutputToken_Works() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.startPrank(seller);
        tokenA.approve(address(tokenTrade), SELL_AMOUNT);
        tokenTrade.setupTrade(address(tokenA), SELL_AMOUNT, ASK_AMOUNT, expiry);
        vm.stopPrank();

        address outputToken = tokenTrade.getOutputToken(0);
        assertEq(outputToken, address(tokenB));
    }
}