// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {EthVault} from "../src/EthVault.sol";

contract EthVaultTest is Test {
    EthVault internal vault;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    // OWNER is this test contract (because we deploy vault in setUp),
    // so it must be able to receive ETH from vault.withdraw().
    receive() external payable {}

    function setUp() public {
        vault = new EthVault();
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    /*//////////////////////////////////////////////////////////////
                                Helpers
    //////////////////////////////////////////////////////////////*/

    function _deposit(address from, uint256 amount) internal {
        vm.prank(from);
        (bool ok, ) = address(vault).call{value: amount}("");
        assertTrue(ok);
    }

    function _expectDeposit(address from, uint256 amount) internal {
        vm.expectEmit(true, true, false, true, address(vault));
        emit EthVault.Deposit(from, amount);
    }

    function _expectWithdraw(address to, uint256 amount) internal {
        vm.expectEmit(true, true, false, true, address(vault));
        emit EthVault.Weethdraw(to, amount);
    }

    function _expectUnauthorized(address caller, uint256 amount) internal {
        vm.expectEmit(true, true, false, true, address(vault));
        emit EthVault.UnauthorizedWithdrawAttempt(caller, amount);
    }

    /*//////////////////////////////////////////////////////////////
                          Group A — Deposits
    //////////////////////////////////////////////////////////////*/

    function test_Deposit_Single_DepositEventAndBalance() public {
        // Arrange
        uint256 amount = 1 ether;
        uint256 vaultBefore = address(vault).balance;

        // Expect
        _expectDeposit(alice, amount);

        // Act
        _deposit(alice, amount);

        // Assert
        assertEq(address(vault).balance, vaultBefore + amount);
    }

    function test_Deposit_MultipleDeposits_SameSender() public {
        // Arrange
        uint256 a1 = 0.4 ether;
        uint256 a2 = 2 ether;
        uint256 vaultBefore = address(vault).balance;

        // Expect (deposit #1)
        _expectDeposit(alice, a1);
        // Act (deposit #1)
        _deposit(alice, a1);

        // Expect (deposit #2)
        _expectDeposit(alice, a2);
        // Act (deposit #2)
        _deposit(alice, a2);

        // Assert
        assertEq(address(vault).balance, vaultBefore + a1 + a2);
    }

    function test_Deposit_DifferentSenders() public {
        // Arrange
        uint256 a = 1.5 ether;
        uint256 b = 0.25 ether;
        uint256 vaultBefore = address(vault).balance;

        // Expect + Act (Alice)
        _expectDeposit(alice, a);
        _deposit(alice, a);

        // Expect + Act (Bob)
        _expectDeposit(bob, b);
        _deposit(bob, b);

        // Assert
        assertEq(address(vault).balance, vaultBefore + a + b);
    }

    /*//////////////////////////////////////////////////////////////
                      Group B — Owner Withdrawal
    //////////////////////////////////////////////////////////////*/

    function test_Withdraw_Owner_Partial() public {
        // Arrange
        uint256 depositAmt = 5 ether;
        uint256 withdrawAmt = 2 ether;
        _deposit(alice, depositAmt);

        uint256 ownerBefore = address(this).balance;
        uint256 vaultBefore = address(vault).balance;

        // Expect
        _expectWithdraw(address(this), withdrawAmt);

        // Act
        vault.withdraw(withdrawAmt);

        // Assert
        assertEq(address(vault).balance, vaultBefore - withdrawAmt);
        assertEq(address(this).balance, ownerBefore + withdrawAmt);
    }

    function test_Withdraw_Owner_FullBalance() public {
        // Arrange
        uint256 depositAmt = 3.3 ether;
        _deposit(bob, depositAmt);

        uint256 ownerBefore = address(this).balance;
        uint256 vaultBefore = address(vault).balance;

        // Expect
        _expectWithdraw(address(this), vaultBefore);

        // Act
        vault.withdraw(vaultBefore);

        // Assert
        assertEq(address(vault).balance, 0);
        assertEq(address(this).balance, ownerBefore + vaultBefore);
    }

    /*//////////////////////////////////////////////////////////////
                  Group C — Unauthorized Withdrawal
    //////////////////////////////////////////////////////////////*/

    function test_Withdraw_NonOwner_DoesNotRevert_EmitsUnauthorized_BalanceUnchanged() public {
        // Arrange
        uint256 depositAmt = 4 ether;
        uint256 withdrawAmt = 1 ether;
        _deposit(alice, depositAmt);

        uint256 vaultBefore = address(vault).balance;

        // Expect
        _expectUnauthorized(alice, withdrawAmt);

        // Act (must NOT revert)
        vm.prank(alice);
        vault.withdraw(withdrawAmt);

        // Assert
        assertEq(address(vault).balance, vaultBefore);
    }

    /*//////////////////////////////////////////////////////////////
                          Group D — Edge Cases
    //////////////////////////////////////////////////////////////*/

    function test_Withdraw_MoreThanBalance_Reverts() public {
        // Arrange
        uint256 depositAmt = 1 ether;
        _deposit(alice, depositAmt);

        uint256 request = depositAmt + 1;

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                EthVault.InsufficientBalance.selector,
                request,
                depositAmt
            )
        );

        // Act
        vault.withdraw(request);

        // Assert
        // (implicit: revert happened as expected)
    }

    function test_Withdraw_ZeroAmount_Succeeds_EmitsEvent_NoBalanceChange() public {
        // Arrange
        uint256 depositAmt = 2 ether;
        _deposit(bob, depositAmt);

        uint256 ownerBefore = address(this).balance;
        uint256 vaultBefore = address(vault).balance;

        // Expect
        _expectWithdraw(address(this), 0);

        // Act
        vault.withdraw(0);

        // Assert
        assertEq(address(vault).balance, vaultBefore);
        assertEq(address(this).balance, ownerBefore);
    }

    function test_MultipleDeposits_ThenOwnerWithdraw_Partial() public {
        // Arrange
        uint256 a = 1 ether;
        uint256 b = 2 ether;
        uint256 c = 0.5 ether;
        uint256 withdrawAmt = 2.25 ether;

        _deposit(alice, a);
        _deposit(bob, b);
        _deposit(alice, c);

        uint256 total = a + b + c;
        uint256 ownerBefore = address(this).balance;

        // Expect
        _expectWithdraw(address(this), withdrawAmt);

        // Act
        vault.withdraw(withdrawAmt);

        // Assert
        assertEq(address(vault).balance, total - withdrawAmt);
        assertEq(address(this).balance, ownerBefore + withdrawAmt);
    }

    /*//////////////////////////////////////////////////////////////
                       Group E — Reentrancy Guard
    //////////////////////////////////////////////////////////////*/

    function test_ReentrancyGuard_BlocksReentrantWithdraw() public {
        // Arrange
        ReentrantOwner attacker = new ReentrantOwner();
        
        // Make attacker the OWNER by deploying vault "from" attacker
        vm.prank(address(attacker));
        EthVault localVault = new EthVault();
        
        attacker.setVault(localVault);
        
        // Deposit funds into the vault
        vm.deal(alice, 10 ether);
        uint256 depositAmt = 5 ether;

        vm.prank(alice);
        (bool okDep, ) = address(localVault).call{value: depositAmt}("");
        assertTrue(okDep);
        assertEq(address(localVault).balance, depositAmt);

        // Expect: outer withdraw succeeds and emits Weethdraw
        vm.expectEmit(true, true, false, true, address(localVault));
        emit EthVault.Weethdraw(address(attacker), 1 ether);

        // Act: attacker (OWNER) withdraws; during transfer, attacker.receive() tries reentering
        attacker.doWithdraw(1 ether);

        // Assert
        assertTrue(attacker.triedReenter());

        // Inner call should revert with Reentrancy()
        bytes memory expected = abi.encodeWithSelector(EthVault.Reentrancy.selector);
        assertEq(attacker.innerRevertData(), expected);

        // Vault balance should only go down by 1 ether once
        assertEq(address(localVault).balance, depositAmt - 1 ether);
    }
}

contract ReentrantOwner {
    EthVault public vault;

    bool public triedReenter;
    bytes public innerRevertData;

    function setVault(EthVault _vault) external {
        vault = _vault;
    }

    receive() external payable {
        if (triedReenter) return;
        triedReenter = true;

        try vault.withdraw(1 wei) {
        } catch (bytes memory reason) {
            innerRevertData = reason;
        }
    }

    function doWithdraw(uint256 amount) external {
        vault.withdraw(amount);
    }
}