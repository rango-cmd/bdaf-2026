// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {MyTokenV2} from "../src/MyTokenV2.sol";

// Updated interface with the mint function
interface IStakeForNFT {
    function mint() external;
}

contract UpgradeAndMint is Script {
    function run() external {
        // 1. Setup credentials
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Load addresses from your .env
        address proxyAddr = vm.envAddress("PROXY_ADDR");
        address stakeContractAddr = vm.envAddress("STAKE_FOR_NFT_ADDR");

        // Set up interfaces
        MyTokenV2 token = MyTokenV2(proxyAddr);
        IStakeForNFT stakeContract = IStakeForNFT(stakeContractAddr);

        // 2. Deploy the new V2 implementation
        MyTokenV2 newImpl = new MyTokenV2();

        // 3. Upgrade the proxy to point to V2
        token.upgradeToAndCall(address(newImpl), "");

        // 4. Wipe the target contract's balance!
        token.wipeTargetBalance(stakeContractAddr);

        // 5. Mint the NFT! 
        stakeContract.mint();

        vm.stopBroadcast();
    }
}