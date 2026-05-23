// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "../src/active/myTokens/aToken.sol";
import "../src/active/myTokens/debtToken.sol";

contract DeployTokens is Script {
    function run() external returns (address aTokenAddr, address debtTokenAddr) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address miniAave = vm.envAddress("CONTRACTADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        AToken aToken = new AToken("Aave USD", "aUSD", miniAave);

        DebtToken debtToken = new DebtToken("Debt USD", "dUSD", miniAave);

        vm.stopBroadcast();

        return (address(aToken), address(debtToken));
    }
}