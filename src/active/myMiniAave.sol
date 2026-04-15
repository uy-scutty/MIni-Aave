// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AToken} from "src/active/myTokens/aToken.sol";
import {DebtToken} from "src/active/myTokens/debtToken.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MyMiniAave is ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address => Reserve) reserves;
    mapping(address => mapping(address => uint256)) userBalance;
    mapping(address => mapping(address => uint256)) userDebt;

    struct Reserve {
        uint256 totalDeposited;
        uint256 totalDebt;
        address aToken;
        address debtToken;
        bool isInitialized;
        uint256 ltv;
        uint256 totalBorrowed;
    }

    error cannotDepositZero();
    error insufficientbalance();
    error ZeroAmount();
    error CannotRepayNothing();
    error BorrowLimitReached();
    error InvalidLtv();
    error ReserveAlreadyInitialized();
    error ReserveNotInitialized();
    error InvalidAsset();
    error InvalidAToken();
    error InvalidDebtToken();

    event deposited(address indexed user, address indexed asset, uint256 indexed amount);
    event withdrawn(address indexed user, address indexed asset, uint256 indexed amount);
    event borrowed(address indexed user, address indexed asset, uint256 amount);
    event repayed(address indexed user, address indexed asset, uint256 amount);

    function deposit(uint256 amount, address asset) public nonReentrant {
        _requireInitialized(asset);
        Reserve storage reserve = reserves[asset];

        if (amount == 0) {
            revert ZeroAmount();
        }

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        reserve.totalDeposited += amount;
        userBalance[msg.sender][asset] += amount;

        AToken(reserve.aToken).mint(msg.sender, amount);
        emit deposited(msg.sender, asset, amount);
    }

    function withdraw(uint256 amount, address asset) public nonReentrant {
        _requireInitialized(asset);
        if (amount == 0) revert ZeroAmount();

        Reserve storage reserve = reserves[asset];

        uint256 availableLiquidity = reserve.totalDeposited - reserve.totalBorrowed;
        if (availableLiquidity < amount) {
            revert insufficientbalance();
        }

        if (userBalance[msg.sender][asset] < amount) {
            revert insufficientbalance();
        }

        userBalance[msg.sender][asset] -= amount;
        reserve.totalDeposited -= amount;

        IERC20(asset).safeTransfer(msg.sender, amount);

        AToken(reserve.aToken).burn(msg.sender, amount);

        emit withdrawn(msg.sender, asset, amount);
    }

    function borrow(address asset, uint256 amount) public nonReentrant {
        _requireInitialized(asset);
        if (amount == 0) {
            revert ZeroAmount();
        }

        Reserve storage reserve = reserves[asset];

        uint256 availableLiquidity = reserve.totalDeposited - reserve.totalBorrowed;
        if (availableLiquidity < amount) {
            revert insufficientbalance();
        }
        uint256 maxBorrow = (userBalance[msg.sender][asset] * reserve.ltv) / 10000;
        if (userDebt[msg.sender][asset] + amount > maxBorrow) {
            revert BorrowLimitReached();
        }

        userDebt[msg.sender][asset] += amount;
        reserve.totalBorrowed += amount;

        IERC20(asset).safeTransfer(msg.sender, amount);
        DebtToken(reserve.debtToken).mint(msg.sender, amount);

        emit borrowed(msg.sender, asset, amount);
    }

    function repay(address asset, uint256 amount) public nonReentrant {
        _requireInitialized(asset);
        if (amount == 0) {
            revert CannotRepayNothing();
        }
        Reserve storage reserve = reserves[asset];

        uint256 debt = userDebt[msg.sender][asset];
        uint256 payAmount = amount > debt ? debt : amount;
        uint256 excess = amount > debt ? amount - debt : 0;

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        userDebt[msg.sender][asset] -= payAmount;
        reserve.totalBorrowed -= payAmount;

        DebtToken(reserve.debtToken).burn(msg.sender, payAmount);

        if (excess > 0) {
            reserve.totalDeposited += excess;
            userBalance[msg.sender][asset] += excess;
            AToken(reserve.aToken).mint(msg.sender, excess);
        }

        emit repayed(msg.sender, asset, amount);
    }

    function getBalance(address user, address asset) public view returns (uint256) {
        _requireInitialized(asset);

        uint256 balanceOfUser = userBalance[user][asset];
        return balanceOfUser;
    }

    function initReserve(address asset, address _aToken, address _debtToken, uint256 _ltv) public {
        Reserve storage reserve = reserves[asset];

        if (reserve.isInitialized) {
            revert ReserveAlreadyInitialized();
        }
        _validateReserve(asset, _aToken, _debtToken, _ltv);

        reserves[asset] = Reserve({
            totalDeposited: 0,
            totalDebt: 0,
            aToken: _aToken,
            debtToken: _debtToken,
            isInitialized: true,
            ltv: _ltv,
            totalBorrowed: 0
        });
    }

    function _validateReserve(address asset, address _aToken, address _debtToken, uint256 _ltv) internal pure {
        if (_ltv > 10000) {
            revert InvalidLtv();
        }
        if (asset == address(0)) {
            revert InvalidAsset();
        }
        if (_aToken == address(0)) {
            revert InvalidAToken();
        }
        if (_debtToken == address(0)) {
            revert InvalidDebtToken();
        }
    }

    function _requireInitialized(address asset) internal view {
        if (!reserves[asset].isInitialized) {
            revert ReserveNotInitialized();
        }
    }
}
