// SPDX-License-Identifier:MIT
pragma solidity 0.8.30;
import {MiniAaveStorage} from "src/miniaavestorage.sol";
import {logic} from "src/logic.sol";
import {Data} from "src/Data.sol";

contract MiniAave is MiniAaveStorage {
    function deposit(address asset, uint256 amount, address onBehalfOf) public {
        logic.depositLogic(
            _reserves,
            _reservesList,
            _userConfig, // in the main protocol code is like _userConfig[onBehalfOf]
            Data.DepositParameters({asset: asset, amount: amount, onBehalfOf: onBehalfOf})
        );
    }
}
