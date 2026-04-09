// SPDX-License-Identifier:MIT
pragma solidity 0.8.30;

import {Data} from "src/Data.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library logic {
    using logic for Data.ReserveData;

    event deposited(address asset, address depositer, uint256 amount);
    error CannotDepositNothing();
    error DepositFailed();

    // my shit is missing the updating intrest rate this just updates the states like get the current interest and everything about the asset from it's reserve
    // missing the minting of token to serve as proof user deposites
    // use as collateral but then not implementing yet cause i am not doing the borrow and repay logic
    // notice fot this deposit function i am reading directly from storage that means higher gascost
    function depositLogic(
        mapping(address => Data.ReserveData) storage reserveData,
        // mapping(uint256 => mapping(address => Data.ReserveData)) storage reserveList,
        // mapping(address => Data.UserConfiguration) storage userConfig,
        Data.DepositParameters memory param
    ) internal {
        Data.ReserveData storage reserve = reserveData[param.asset];
        reserve.updateState();

        if (param.amount == 0) {
            revert CannotDepositNothing();
        }

        bool success = IERC20(param.asset).transferFrom(msg.sender, address(this), param.amount);
        // how is it still telling me the success is not used here when i run forge build
        if (!success) {
            revert DepositFailed();
        }

        emit deposited(param.asset, msg.sender, param.amount);
    }

    function updateState(Data.ReserveData storage self) internal {
        if (block.timestamp == self.lastUpdateTimeStamp) {
            return;
        }
        // do some intrest math still work on that
        self.lastUpdateTimeStamp = block.timestamp;
    }
}
