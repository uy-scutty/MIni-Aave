// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "src/mocks/MockV3Aggregator.sol";

contract DeployMockPriceFeed is Script {
    function run() external returns (address) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        uint8 decimals = uint8(vm.envUint("PRICE_DECIMALS"));
        int256 initialPrice = int256(vm.envUint("BTC_INITIAL_PRICE"));

        vm.startBroadcast(deployerKey);

        MockV3Aggregator priceFeed = new MockV3Aggregator(decimals, initialPrice);

        vm.stopBroadcast();

        return address(priceFeed);
    }
}
