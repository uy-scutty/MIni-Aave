// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {BTCToken} from "src/active/testTokens/btcToken.sol";
import {USDToken} from "src/active/testTokens/USDToken.sol";

contract DeployTestTokens is Script {
    function run() external returns (address, address) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        BTCToken  BTC = new BTCToken();
        USDToken USD = new USDToken();

        vm.stopBroadcast();

        return (address(BTC), address(USD));
    }
}
