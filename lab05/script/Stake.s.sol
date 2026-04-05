// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {MyTokenV1} from "../src/MyTokenV1.sol";

// Interface for the target contract
interface IStakeForNFT {
    // call stake function with token address, amount, and student ID
    function stake(address token, uint256 amount, string calldata studentId) external;
}

contract Stake is Script {
    function run() external {
        // 1. Setup credentials
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // 2. Set up the target StakeForNFT contract
        address stakeContractAddr = vm.envAddress("STAKE_FOR_NFT_ADDR");
        IStakeForNFT stakeContract = IStakeForNFT(stakeContractAddr);
        // 3. Wrap the existing token contract with the ERC1967Proxy to get the proxy address
        address proxyAddr = vm.envAddress("PROXY_ADDR");
        MyTokenV1 token = MyTokenV1(proxyAddr);
        // 4. Approve the StakeForNFT contract to spend tokens on behalf of the deployer
        uint256 stakeAmount = 1000 * 1e18; // Stake 1000 tokens
        string memory studentId = vm.envString("STUDENT_ID");
        token.approve(stakeContractAddr, stakeAmount);
        stakeContract.stake(address(token), stakeAmount, studentId);
        vm.stopBroadcast();
    }
}