// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.30;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// import {AToken} from "src/active/myTokens/aToken.sol";
// import {DebtToken} from "src/active/myTokens/debtToken.sol";

// contract MyMiniAave is Ownable {
//     struct Reserve {
//         address asset;
//         address aToken;
//         address debtToken;
//         bool isInitialized;
//         uint256 ltv;
//         uint256 liquidationThreshold;
// uint256 liquidationBonus;
//     }

//     mapping(address => Reserve) public reserves;
//     address[] public reserveList;

//     error ReserveAlreadyInitialized();
//     error InvalidAsset();
//     error InvalidERC20();
//     error InvalidConfig();

//     constructor(address admin) Ownable(admin) {}

//     function initReserve(
//         address asset,
//         uint256 ltv,
//         uint256 liquidationThreshold,
//         uint256 liquidationBonus
//     ) external onlyOwner {
//         if (reserves[asset].isInitialized) {
//             revert ReserveAlreadyInitialized();
//         }

//         if (asset == address(0)) revert InvalidAsset();

//         // sanity check token behaves like ERC20
//         _validateERC20(asset);

//         // config checks
//         if (ltv > 10000) revert InvalidConfig();
//         if (ltv > liquidationThreshold) revert InvalidConfig();
//         if (liquidationBonus > 2000) revert InvalidConfig(); // max 20%

//         // deploy protocol-controlled wrappers
//         AToken aToken = new AToken(
//             string.concat("Mini Aave ", _symbol(asset)),
//             string.concat("ma", _symbol(asset)),
//             address(this)
//         );

//         DebtToken debtToken = new DebtToken(
//             string.concat("Mini Debt ", _symbol(asset)),
//             string.concat("md", _symbol(asset)),
//             address(this)
//         );

//         reserves[asset] = Reserve({
//             asset: asset,
//             aToken: address(aToken),
//             debtToken: address(debtToken),
//             isInitialized: true,
//             ltv: ltv,
//             liquidationThreshold: liquidationThreshold,
//             liquidationBonus: liquidationBonus
//         });

//         reserveList.push(asset);
//     }

//     function _validateERC20(address asset) internal view {
//         // if these calls fail, token is likely invalid
//         IERC20(asset).totalSupply();
//         IERC20(asset).balanceOf(address(this));
//     }

//     function _symbol(address asset) internal view returns (string memory) {
//         (bool ok, bytes memory data) =
//             asset.staticcall(abi.encodeWithSignature("symbol()"));

//         if (!ok || data.length == 0) {
//             return "TOKEN";
//         }

//         return abi.decode(data, (string));
//     }
// }
