// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {MyMiniAave} from "src/active/myMiniAave.sol";

contract InitReserve is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        address miniAave = vm.envAddress("CONTRACTADDRESS");

        address asset = vm.envAddress("USD");
        address aToken = vm.envAddress("aUSD");
        address debtToken = vm.envAddress("dUSD");
        address priceFeed = vm.envAddress("USD_PRICEFEED");

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
