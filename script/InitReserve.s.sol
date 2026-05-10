// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {MyMiniAave} from "src/active/myMiniAave.sol";

contract InitReserve is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        address miniAave = 0x5FbDB2315678afecb367f032d93F642f64180aa3;

        address asset = vm.envAddress("TOKEN");
        address aToken = vm.envAddress("ATOKEN");
        address debtToken = vm.envAddress("DEBTTOKEN");
        address priceFeed = vm.envAddress("PRICEFEED");

        vm.startBroadcast(pk);

        MyMiniAave(miniAave)
            .initReserve(
                asset,
                aToken,
                debtToken,
                7500, // LTV = 75%
                8000, // liquidation threshold
                500, // liquidation bonus
                priceFeed // dummy price feed for now
            );

        vm.stopBroadcast();
    }
}
