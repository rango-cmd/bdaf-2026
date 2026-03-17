// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TokenGold} from "../src/TokenGold.sol";

contract DeployTokenGold is Script {
    function run() external returns (TokenGold token) {
        vm.startBroadcast();

        token = new TokenGold();

        vm.stopBroadcast();

        console.log("TokenGold deployed at:", address(token));
    }
}