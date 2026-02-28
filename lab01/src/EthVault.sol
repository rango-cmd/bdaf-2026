// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title EthVault
/// @notice Minimal ETH vault with owner-only withdrawal and reentrancy protection.
/// @dev
/// Design decisions:
/// - Anyone can deposit ETH via receive/fallback.
/// - Only OWNER can withdraw.
/// - Non-owner withdrawal attempts DO NOT revert (emit event and return).
/// - Uses a simple reentrancy guard on withdraw().
contract EthVault {

    /// @notice Address that deployed the contract.
    /// @dev Immutable → stored in bytecode (cheaper than storage).
    address public immutable OWNER;

    /*//////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted whenever ETH is received.
    /// @param sender Address sending ETH
    /// @param amount Amount of ETH received (wei)
    event Deposit(address indexed sender, uint256 amount);

    /// @notice Emitted when OWNER successfully withdraws ETH.
    /// @dev Spelling intentionally preserved as "Weethdraw" per assignment.
    event Weethdraw(address indexed to, uint256 amount);

    /// @notice Emitted when a non-owner attempts withdrawal.
    event UnauthorizedWithdrawAttempt(address indexed caller, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                Errors
    //////////////////////////////////////////////////////////////*/
    /// @notice Thrown when withdrawal amount exceeds contract balance.
    error InsufficientBalance(uint256 requested, uint256 available);

    /// @notice Thrown if ETH transfer to OWNER fails.
    error EthTransferFailed();

    /// @notice Thrown if a reentrant call is detected.
    error Reentrancy();

    /*//////////////////////////////////////////////////////////////
                        Reentrancy Guard Storage
    //////////////////////////////////////////////////////////////*/

    /// @dev Reentrancy state:
    /// 1 = NOT_ENTERED
    /// 2 = ENTERED
    uint256 private _status = 1;

    /// @dev Prevents reentrant calls to protected functions.
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    /// @dev Executed before function body.
    /// Reverts if already entered.
    function _nonReentrantBefore() internal {
        if (_status != 1) revert Reentrancy();
        _status = 2;
    }
    
    /// @dev Executed after function body.
    /// Resets reentrancy state.
    function _nonReentrantAfter() internal {
        _status = 1;
    }

    /*//////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets deployer as OWNER.
    constructor() {
        OWNER = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                            ETH Reception
    //////////////////////////////////////////////////////////////*/

    /// @notice Accepts plain ETH transfers.
    /// @dev Always emits Deposit event (even for 0 wei).
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Handles calls with unknown calldata.
    /// @dev Emits Deposit only if ETH was actually sent.
    fallback() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            Withdrawal Logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraws `amount` wei to OWNER.
    /// @dev
    /// - Protected by nonReentrant modifier.
    /// - If caller != OWNER: emits event and returns (no revert).
    /// - Reverts if amount > contract balance.
    function withdraw(uint256 amount) external nonReentrant {

        // If caller is not OWNER, emit event and exit.
        if (msg.sender != OWNER) {
            emit UnauthorizedWithdrawAttempt(msg.sender, amount);
            return;
        }

        // Cache balance (gas optimization).
        uint256 bal = address(this).balance;

        // Ensure sufficient balance.
        if (amount > bal) revert InsufficientBalance(amount, bal);

        // External call (reentrancy window protected by guard).
        (bool ok, ) = OWNER.call{value: amount}("");
        if (!ok) revert EthTransferFailed();

        // Emit success event.
        emit Weethdraw(OWNER, amount);
    }
}