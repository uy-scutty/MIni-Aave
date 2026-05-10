// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/active/myMiniAave.sol";

contract DeployMyMiniAave is Script {
    function run() external {
        vm.startBroadcast();

        new MyMiniAave(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

        vm.stopBroadcast();
    }
}
