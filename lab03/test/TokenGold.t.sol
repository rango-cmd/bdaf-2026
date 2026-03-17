// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {TokenGold} from "../src/TokenGold.sol";

contract TokenGoldTest is Test {
    using MessageHashUtils for bytes32;

    TokenGold internal token;

    uint256 internal alicePrivateKey = 0xA11CE;
    uint256 internal bobPrivateKey = 0xB0B;
    uint256 internal badPrivateKey = 0xBAD;

    address internal alice;
    address internal bob;
    address internal bad;

    uint256 internal constant INITIAL_ALICE_BALANCE = 1_000 ether;
    uint256 internal constant PERMIT_VALUE = 100 ether;

    /**
     * @dev Setup runs before each test
     * - Deploy contract
     * - Create test accounts
     * - Give Alice some tokens
     */
    function setUp() public {
        token = new TokenGold();

        alice = vm.addr(alicePrivateKey);
        console.log('Alice Address:', alice);

        bob = vm.addr(bobPrivateKey);
        console.log('Bob Address:', bob);

        bad = vm.addr(badPrivateKey);
        console.log('Bad Address:', bad);

        // Give Alice some GLD tokens to use in permit / transferFrom tests.
        assertTrue(token.transfer(alice, INITIAL_ALICE_BALANCE));
        console.log('Alice Balance:', token.balanceOf(alice));
    }

    /**
     * @dev Helper: simulate off-chain signing
     * Recreates the exact hash used in permit()
     */
    function _signMessage(
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline,
        uint256 privateKey
    ) internal view returns (bytes memory signature) {
        // Step 1: recreate message hash (same as contract)
        bytes32 hash = keccak256(
            abi.encodePacked(
                owner,
                spender,
                value,
                nonce,
                deadline,
                address(token)
            )
        );
        console.log("Hash:");
        console.logBytes32(hash);
        
        // Step 2: convert to Ethereum signed message
        bytes32 message = hash.toEthSignedMessageHash();
        console.log("Message:");
        console.logBytes32(message);

        // Step 3: sign with private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, message);

        // Step 4: combine into signature
        signature = abi.encodePacked(r, s, v);
        console.log("Signature:");
        console.logBytes(signature);
    }

    /// Test: valid permit works
    function test_Permit_Valid() public {
        uint256 nonce = token.nonces(alice);
        console.log('Nonce[Alice]:', nonce);

        uint256 deadline = block.timestamp + 1 days;
        console.log('Deadline:', deadline);

        bytes memory signature = _signMessage(
            alice, 
            bob, 
            PERMIT_VALUE, 
            nonce, 
            deadline, 
            alicePrivateKey
        );

        vm.prank(bob);
        token.permit(alice, bob, PERMIT_VALUE, nonce, deadline, signature);
        
        console.log("Allowed Token: ", token.allowance(alice, bob));
        assertEq(token.allowance(alice, bob), PERMIT_VALUE);

        console.log("Nonces[Alice]: ", token.nonces(alice));
        assertEq(token.nonces(alice), nonce + 1);
    }

    /// Test: invalid signer
    function test_Permit_InvalidSinger() public {
        uint256 nonce = token.nonces(alice);
        console.log('Nonce[Alice]:', nonce);

        uint256 deadline = block.timestamp + 1 days;
        console.log('Deadline:', deadline);

        // Bad signs, but owner is Alice.
        bytes memory signature = _signMessage(
            alice, 
            bob, 
            PERMIT_VALUE, 
            nonce, 
            deadline, 
            badPrivateKey
        );

        vm.prank(bob);
        vm.expectRevert(TokenGold.InvalidSignature.selector);
        token.permit(alice, bob, PERMIT_VALUE, nonce, deadline, signature);
    }

    /// Test: replay attack (same signature twice)
    function test_Permit_ReusingSignature() public {
        uint256 nonce = token.nonces(alice);
        console.log('Nonce[Alice]:', nonce);

        uint256 deadline = block.timestamp + 1 days;
        console.log('Deadline:', deadline);

        bytes memory signature = _signMessage(
            alice, 
            bob, 
            PERMIT_VALUE, 
            nonce, 
            deadline, 
            alicePrivateKey
        );

        vm.startPrank(bob);
        // First use → OK
        token.permit(alice, bob, PERMIT_VALUE, nonce, deadline, signature);

        // Second use → should fail
        vm.expectRevert(TokenGold.InvalidNonce.selector);
        token.permit(alice, bob, PERMIT_VALUE, nonce, deadline, signature);

        vm.stopPrank();
    }

    /// Test: expired signature
    function test_Permit_SignatureExpired() public {
        uint256 nonce = token.nonces(alice);
        console.log('Nonce[Alice]:', nonce);

        uint256 deadline = block.timestamp + 1 days;
        console.log('Deadline:', deadline);

        bytes memory signature = _signMessage(
            alice, 
            bob, 
            PERMIT_VALUE, 
            nonce, 
            deadline, 
            alicePrivateKey
        );

        // Make block.timestamp > deadline
        vm.warp(deadline + 2);

        vm.prank(bob);
        vm.expectRevert(TokenGold.SignatureExpired.selector);
        token.permit(alice, bob, PERMIT_VALUE, nonce, deadline, signature);
    }

    /// Test: transferFrom works after permit
    function test_TransferFrom_WorksAfterPermit() public {
        uint256 nonce = token.nonces(alice);
        console.log('Nonce[Alice]:', nonce);

        uint256 deadline = block.timestamp + 1 days;
        console.log('Deadline:', deadline);

        uint256 transferFromAmount = 50 ether;

        bytes memory signature = _signMessage(
            alice, 
            bob, 
            PERMIT_VALUE, 
            nonce, 
            deadline, 
            alicePrivateKey
        );

        vm.startPrank(bob);
        token.permit(alice, bob, PERMIT_VALUE, nonce, deadline, signature);
        assertTrue(token.transferFrom(alice, bob, transferFromAmount));

        console.log("Bob's Token: ", token.balanceOf(bob));
        assertEq(token.balanceOf(bob), transferFromAmount);
        
        console.log("Alice's Token: ", token.balanceOf(alice));
        assertEq(token.balanceOf(alice), INITIAL_ALICE_BALANCE - transferFromAmount);

        console.log("Rest of allowed Token: ", token.allowance(alice, bob));
        assertEq(token.allowance(alice, bob), PERMIT_VALUE - transferFromAmount);
    }

    /// Test: transferFrom without permit
    function test_TransferFrom_NoPermit() public {
        uint256 transferFromAmount = 50 ether;

        vm.prank(bob);
        vm.expectRevert();
        assertFalse(token.transferFrom(alice, bob, transferFromAmount));
    }
}