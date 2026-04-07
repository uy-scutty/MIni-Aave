// SPDX-License-Identifier:MIT
pragma solidity 0.8.30;

import {Data} from "src/Data.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library logic {
    using logic for Data.ReserveData;

    event deposited(address asset, address depositer, uint256 amount);
    error CannotDepositNothing();

    function depositLogic(
        mapping(address => Data.ReserveData) storage reserveData,
        mapping(uint256 => mapping(address => Data.ReserveData)) storage reserveList,
        mapping(address => Data.UserConfiguration) storage userConfig,
        Data.DepositParameters memory param
    ) internal {
        if (param.amount == 0) {
            revert CannotDepositNothing();
        }

        Data.ReserveData storage reserve = reserveData[param.asset];

        reserve.updateState();

        IERC20(param.asset).transferFrom(msg.sender, address(this), param.amount);

        emit deposited(param.asset, msg.sender, param.amount);
    }

    function updateState(Data.ReserveData storage self) internal {
        if (block.timestamp == self.lastUpdateTimeStamp) {
            return;
        }

        self.lastUpdateTimeStamp = block.timestamp;
    }
}
