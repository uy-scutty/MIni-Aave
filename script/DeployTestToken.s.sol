// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {TestToken} from "src/active/TestToken.sol";

contract DeployTestTokens is Script {
    function run() external returns (TestToken) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        TestToken token = new TestToken();

        vm.stopBroadcast();

        return token;
    }
}
