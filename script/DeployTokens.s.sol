// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../src/active/myTokens/aToken.sol";
import "../src/active/myTokens/debtToken.sol";

contract DeployTokens is Script {
    function run() external returns (address aTokenAddr, address debtTokenAddr) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address miniAave = 0x5FbDB2315678afecb367f032d93F642f64180aa3;

        vm.startBroadcast(deployerPrivateKey);

        AToken aToken = new AToken("AToken", "aTT", miniAave);

        DebtToken debtToken = new DebtToken("DebtToken", "dTT", miniAave);

        vm.stopBroadcast();

        return (address(aToken), address(debtToken));
    }
}
