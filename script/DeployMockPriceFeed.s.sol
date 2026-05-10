// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "src/mocks/MockV3Aggregator.sol";

contract DeployMockPriceFeed is Script {
    function run() external returns (MockV3Aggregator) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        // Example ETH/USD price = 2000 * 1e8
        MockV3Aggregator priceFeed = new MockV3Aggregator(8, 2000e8);

        vm.stopBroadcast();

        return priceFeed;
    }
}
