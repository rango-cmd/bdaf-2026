// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract TokenGold is ERC20 {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 1e18;

    mapping (address=>uint256) public nonces;

    error InvalidNonce();
    error SignatureExpired();
    error InvalidSignature();

    constructor() ERC20("TokenGold", "GLD"){
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) public {
        /// nonce
        if (nonce != nonces[owner]) revert InvalidNonce();
        
        /// deadline
        if (block.timestamp > deadline) revert SignatureExpired();

        /// signature
        bytes32 hash = keccak256(
            abi.encodePacked(
                owner,
                spender,
                value,
                nonce,
                deadline,
                address(this)
            )
        );
        bytes32 message = hash.toEthSignedMessageHash();
        address signer = ECDSA.recover(message, signature);

        if (signer != owner) revert InvalidSignature();

        /// execute
        _approve(owner, spender, value);
        nonces[owner]++;
    }
}