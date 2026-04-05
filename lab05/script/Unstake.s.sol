// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";

interface IStakeForNFT {
    // call unstake function to unstake tokens
    function unstake() external;
}

contract Unstake is Script {
    function run() external {
        // 1. Setup credentials
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 2. Set up the target StakeForNFT contract
        address stakeContractAddr = vm.envAddress("STAKE_FOR_NFT_ADDR");
        IStakeForNFT stakeContract = IStakeForNFT(stakeContractAddr);

        // 3. Unstake tokens
        stakeContract.unstake();
        vm.stopBroadcast();
    }
}