// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TokenA} from "../src/TokenA.sol";
import {TokenB} from "../src/TokenB.sol";
import {TokenTrade} from "../src/TokenTrade.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        TokenA tokenA = new TokenA();
        TokenB tokenB = new TokenB();

        TokenTrade tokenTrade = new TokenTrade(
            address(tokenA),
            address(tokenB)
        );

        vm.stopBroadcast();

        console.log("TokenA:", address(tokenA));
        console.log("TokenB:", address(tokenB));
        console.log("TokenTrade:", address(tokenTrade));
    }
}