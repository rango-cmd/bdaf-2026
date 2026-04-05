// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Script} from "forge-std/Script.sol";
import {MyTokenV1} from "../src/MyTokenV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy is Script {
    function run() external {
        // 1. Setup credentials
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 2. Deploy V1 Implementation
        MyTokenV1 impl = new MyTokenV1();

        // 3. Encode initialization data and deploy the Proxy
        bytes memory data = abi.encodeCall(
            MyTokenV1.initialize,
            ("MyToken", "MTK", 1000000 * 1e18) 
        );
        new ERC1967Proxy(address(impl), data);

        vm.stopBroadcast();
    }
}