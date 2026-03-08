// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title TokenTrade
/// @notice Simple peer-to-peer trading contract for TokenA and TokenB
/// @dev Sellers deposit tokens and set the amount of the other token they want.
/// Buyers can settle the trade before expiry. A 0.1% fee is collected by the owner.
contract TokenTrade {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice Caller is not the contract owner
    error NotOwner();
    
    /// @notice Token is not supported for trading
    error InvalidToken();
    
    /// @notice Invalid token amount
    error InvalidAmount();
    
    /// @notice Expiry time must be in the future
    error InvalidExpiry();
    
    /// @notice Trade ID does not exist
    error TradeNotFound();
    
    /// @notice Trade already settled
    error TradeAlreadySettled();
    
    /// @notice Trade already cancelled
    error TradeAlreadyCancelled();
    
    /// @notice Trade expired and cannot be settled
    error TradeExpired();
    
    /// @notice Trade has not expired yet
    error TradeNotExpired();
    
    /// @notice Caller is not the seller of the trade
    error NotSeller();

    /*//////////////////////////////////////////////////////////////
                                STRUCT
    //////////////////////////////////////////////////////////////*/
    /// @notice Represents a trade created by a seller
    struct Trade {
        address seller;             // Address that created the trade
        address inputToken;         // Token deposited by seller
        uint256 inputAmount;        // Amount of token deposited
        uint256 outputAsk;          // Amount of the other token requested
        uint256 expiry;             // Expiration timestamp
        bool settled;               // True if trade was completed
        bool cancelled;             // True if seller cancelled after expiry
    }

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    /// @notice Contract owner who can withdraw collected fees
    address public immutable OWNER;

    /// @notice Address of TokenA
    address public immutable TOKEN_A;
    
    /// @notice Address of TokenB
    address public immutable TOKEN_B;
    
    /// @notice Incremental trade ID
    uint256 public nextTradeId;
    
    /// @notice Mapping of trade ID to Trade struct
    mapping(uint256 => Trade) public trades;
    
    /// @notice Accumulated protocol fees for each token
    mapping(address => uint256) public accumulatedFees;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a trade is created
    event TradeSetup(
        uint256 indexed tradeId,
        address indexed seller,
        address indexed inputToken,
        uint256 inputAmount,
        uint256 outputAsk,
        uint256 expiry
    );

    /// @notice Emitted when a trade is successfully settled
    event TradeSettled(
        uint256 indexed tradeId,
        address indexed seller,
        address indexed buyer,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 fee
    );

    /// @notice Emitted when a trade is cancelled after expiry
    event TradeCancelled(uint256 indexed tradeId, address indexed seller);

    /// @notice Emitted when the owner withdraws collected fees
    event FeeWithdrawn(address indexed token, address indexed owner, uint256 amount);
    
    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/
    /// @notice Restricts function to contract owner
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
    
    function _onlyOwner() view internal {
        if (msg.sender != OWNER) revert NotOwner();
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Initialize trading contract with token pair
    /// @param _tokenA Address of TokenA
    /// @param _tokenB Address of TokenB
    constructor(address _tokenA, address _tokenB) {
        if (_tokenA == address(0) || _tokenB == address(0) || _tokenA == _tokenB) {
            revert InvalidToken();
        }

        OWNER = msg.sender;
        TOKEN_A = _tokenA;
        TOKEN_B = _tokenB;
    }

    /*//////////////////////////////////////////////////////////////
                                TRADE LOGIC
    //////////////////////////////////////////////////////////////*/
    /// @notice Create a new trade by depositing tokens
    /// @param inputToken Token the seller wants to trade
    /// @param inputAmount Amount of tokens deposited
    /// @param outputAsk Amount of the other token requested
    /// @param expiry Expiration timestamp for the trade
    function setupTrade(
        address inputToken,
        uint256 inputAmount,
        uint256 outputAsk,
        uint256 expiry
    ) external {
        if (!_isAllowedToken(inputToken)) revert InvalidToken();
        if (inputAmount == 0 || outputAsk == 0) revert InvalidAmount();
        if (expiry <= block.timestamp) revert InvalidExpiry();

        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);

        uint256 tradeId = nextTradeId;

        trades[tradeId] = Trade({
            seller: msg.sender,
            inputToken: inputToken,
            inputAmount: inputAmount,
            outputAsk: outputAsk,
            expiry: expiry,
            settled: false,
            cancelled: false
        });

        nextTradeId++;

        emit TradeSetup(tradeId, msg.sender, inputToken, inputAmount, outputAsk, expiry);
    }

    /// @notice Fulfill an existing trade
    /// @param tradeId ID of the trade to settle
    function settleTrade(uint256 tradeId) external {
        Trade storage trade = trades[tradeId];

        if (trade.seller == address(0)) revert TradeNotFound();
        if (trade.settled) revert TradeAlreadySettled();
        if (trade.cancelled) revert TradeAlreadyCancelled();
        if (block.timestamp > trade.expiry) revert TradeExpired();

        address outputToken = _getOtherToken(trade.inputToken);

        // Calculate protocol fee (0.1%)
        uint256 fee = trade.outputAsk / 1000; // 0.1%
        uint256 sellerReceives = trade.outputAsk - fee;

        // Transfer buyer payment
        IERC20(outputToken).safeTransferFrom(msg.sender, address(this), trade.outputAsk);

        // Send tokens to seller
        IERC20(outputToken).safeTransfer(trade.seller, sellerReceives);

        // Send deposited tokens to buyer
        IERC20(trade.inputToken).safeTransfer(msg.sender, trade.inputAmount);

        accumulatedFees[outputToken] += fee;
        trade.settled = true;

        emit TradeSettled(
            tradeId,
            trade.seller,
            msg.sender,
            trade.inputToken,
            outputToken,
            trade.inputAmount,
            trade.outputAsk,
            fee
        );
    }

    /// @notice Cancel a trade after it expires
    /// @param tradeId ID of the trade to cancel
    function cancelExpiredTrade(uint256 tradeId) external {
        Trade storage trade = trades[tradeId];

        if (trade.seller == address(0)) revert TradeNotFound();
        if (trade.seller != msg.sender) revert NotSeller();
        if (trade.settled) revert TradeAlreadySettled();
        if (trade.cancelled) revert TradeAlreadyCancelled();
        if (block.timestamp <= trade.expiry) revert TradeNotExpired();

        trade.cancelled = true;
        IERC20(trade.inputToken).safeTransfer(trade.seller, trade.inputAmount);

        emit TradeCancelled(tradeId, trade.seller);
    }

    /*//////////////////////////////////////////////////////////////
                                FEE LOGIC
    //////////////////////////////////////////////////////////////*/
    /// @notice Withdraw accumulated protocol fees
    /// @dev Only the owner can withdraw fees
    function withdrawFee() external onlyOwner {
        _withdrawTokenFee(TOKEN_A);
        _withdrawTokenFee(TOKEN_B);
    }

    /// @dev Internal function to withdraw fee of a specific token
    function _withdrawTokenFee(address token) internal {
        uint256 amount = accumulatedFees[token];
        if (amount == 0) return;

        accumulatedFees[token] = 0;
        IERC20(token).safeTransfer(OWNER, amount);

        emit FeeWithdrawn(token, OWNER, amount);
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the output token for a given trade
    function getOutputToken(uint256 tradeId) external view returns (address) {
        Trade memory trade = trades[tradeId];
        if (trade.seller == address(0)) revert TradeNotFound();

        return _getOtherToken(trade.inputToken);
    }
    
    /// @dev Check if token is allowed for trading
    function _isAllowedToken(address token) internal view returns (bool) {
        return token == TOKEN_A || token == TOKEN_B;
    }

    /// @dev Return the opposite token in the pair
    function _getOtherToken(address inputToken) internal view returns (address) {
        if (inputToken == TOKEN_A) return TOKEN_B;
        if (inputToken == TOKEN_B) return TOKEN_A;
        revert InvalidToken();
    }
}