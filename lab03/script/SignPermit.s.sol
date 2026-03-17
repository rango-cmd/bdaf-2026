// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {TokenGold} from "../src/TokenGold.sol";

contract SignPermit is Script {
    using MessageHashUtils for bytes32;

    function run() external view {
        address tokenAddr = vm.envAddress("TOKEN_GOLD_ADDRESS");
        address owner = vm.envAddress("ALICE_ADDRESS");
        address spender = vm.envAddress("BOB_ADDRESS");
        uint256 value = 50000000000000000000;
        uint256 nonce = 0;
        uint256 deadline = 1773796712;
        uint256 alicePk = vm.envUint("ALICE_PRIVATE_KEY");

        bytes32 hash = keccak256(
            abi.encodePacked(
                owner,
                spender,
                value,
                nonce,
                deadline,
                tokenAddr
            )
        );

        bytes32 message = hash.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, message);
        bytes memory signature = abi.encodePacked(r, s, v);

        console.log("hash:");
        console.logBytes32(hash);
        console.log("message:");
        console.logBytes32(message);
        console.log("signature:");
        console.logBytes(signature);
    }
}