// SPDX-License-Identifier:MIT
pragma solidity 0.8.30;

library Data {
    struct ReserveData {
        uint8 id;
        uint256 liquidityIndex;
        address aTokenAddress;
        uint256 lastUpdateTimeStamp;
    }

    struct UserConfiguration {
        uint256 data;
    }

    struct DepositParameters {
        address asset;
        uint256 amount;
        address onBehalfOf;
    }
}
