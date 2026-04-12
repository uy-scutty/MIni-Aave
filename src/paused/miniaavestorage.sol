// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
import {Data} from "src/paused/Data.sol";

contract MiniAaveStorage {
    mapping(address => Data.ReserveData) internal _reserves;

    mapping(uint256 => mapping(address => Data.ReserveData)) internal _reservesList;

    mapping(address => Data.UserConfiguration) internal _userConfig;
}
