// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AToken} from "src/active/myTokens/aToken.sol";
import {DebtToken} from "src/active/myTokens/debtToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// need to add governace contract who can call the init
// recomended i use my wallet do not get this sha i pass in constructor
contract MyMiniAave is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    mapping(address => Reserve) reserves;
    mapping(address => mapping(address => uint256)) userBalance;
    mapping(address => mapping(address => uint256)) userDebt;

    address[] public reserveList;

    struct Reserve {
        uint256 totalDeposited;
        uint256 totalBorrowed;
        address aToken;
        address debtToken;
        bool isInitialized;
        uint256 ltv;

        uint256 liquidationThreshold;
        uint256 liquidationBonus;
    }
    constructor(address admin) Ownable(admin) {}

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
    error InvalidConfig();
    error LiquidationBonusTooLow();
    error NotLiquidatable();
    error TooMuchPay();
    error CannotWithdraw();
    error CannotBorrow();
    error TooLow();

    event Deposited(address indexed user, address indexed asset, uint256 amount);
    event Withdrawn(address indexed user, address indexed asset, uint256 amount);
    event Borrowed(address indexed user, address indexed asset, uint256 amount);
    event Repaid(address indexed user, address indexed asset, uint256 amount);
    event Liquidated(address indexed user, address indexed debtAsset, address indexed collateralAsset, uint256 amount);

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
        emit Deposited(msg.sender, asset, amount);
    }

    function withdraw(uint256 amount, address asset) public nonReentrant {
        _requireInitialized(asset);
        if (amount == 0) revert ZeroAmount();

        Reserve storage reserve = reserves[asset];

        if (userBalance[msg.sender][asset] < amount) {
            revert insufficientbalance();
        }

        uint256 availableLiquidity = reserve.totalDeposited - reserve.totalBorrowed;
        if (availableLiquidity < amount) {
            revert insufficientbalance();
        }

        userBalance[msg.sender][asset] -= amount;
        reserve.totalDeposited -= amount;

        if (calculateHealthFactor(msg.sender) < 1e18) {
            revert CannotWithdraw();
        }

        IERC20(asset).safeTransfer(msg.sender, amount);

        AToken(reserve.aToken).burn(msg.sender, amount);

        emit Withdrawn(msg.sender, asset, amount);
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

        if (calculateHealthFactor(msg.sender) < 1e18) {
            revert CannotBorrow();
        }

        IERC20(asset).safeTransfer(msg.sender, amount);
        DebtToken(reserve.debtToken).mint(msg.sender, amount);

        emit Borrowed(msg.sender, asset, amount);
    }

    function repay(address asset, uint256 amount) public nonReentrant {
        _requireInitialized(asset);
        if (amount == 0) {
            revert CannotRepayNothing();
        }
        Reserve storage reserve = reserves[asset];

        uint256 debt = userDebt[msg.sender][asset];
        // i do not understand this
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

        emit Repaid(msg.sender, asset, payAmount);
    }

    function getBalance(address user, address asset) public view returns (uint256) {
        _requireInitialized(asset);

        uint256 balanceOfUser = userBalance[user][asset];
        return balanceOfUser;
    }

    // fix this add access control like who can call basically i feel like only this contract should be able to init a reserve or should be able to init a reserve
    // not there is the thing about users can add they own fake token but protocol cannot add fake token
    function initReserve(
        address asset,
        address _aToken,
        address _debtToken,
        uint256 _ltv,
        uint256 _liquidationThreshold,
        uint256 _liquidationBonus
    ) external onlyOwner {
        Reserve storage reserve = reserves[asset];

        if (reserve.isInitialized) {
            revert ReserveAlreadyInitialized();
        }
        _validateReserve(asset, _aToken, _debtToken, _ltv, _liquidationThreshold, _liquidationBonus);

        reserves[asset] = Reserve({
            totalDeposited: 0,
            aToken: _aToken,
            debtToken: _debtToken,
            isInitialized: true,
            ltv: _ltv,
            totalBorrowed: 0,
            liquidationThreshold: _liquidationThreshold,
            liquidationBonus: _liquidationBonus
        });

        reserveList.push(asset);
    }

    function _validateReserve(
        address asset,
        address _aToken,
        address _debtToken,
        uint256 _ltv,
        uint256 _liquidationThreshold,
        uint256 _liquidationBonus
    ) internal pure {
        if (_ltv > 10000) {
            revert InvalidLtv();
        }

        if (_ltv > _liquidationThreshold) {
            revert InvalidConfig();
        }
        if (_liquidationBonus > 2000) {
            revert InvalidConfig();
        }
        if (_liquidationBonus < 100) {
            revert TooLow();
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

    function getTotalCollateral(address user) public view returns (uint256) {
        uint256 length = reserveList.length;
        uint256 totalCollateral;

        for (uint256 i = 0; i < length; i++) {
            address asset = reserveList[i];
            totalCollateral += userBalance[user][asset];
        }
        return totalCollateral;
    }

    function getTotalDebt(address user) public view returns (uint256) {
        uint256 length = reserveList.length;
        uint256 totalDebt_;

        for (uint256 i = 0; i < length; i++) {
            address asset = reserveList[i];
            totalDebt_ += userDebt[user][asset];
        }
        return totalDebt_;
    }

    function calculateHealthFactor(address user) public view returns (uint256) {
        uint256 totalDebt_ = getTotalDebt(user);
        if (totalDebt_ == 0) {
            return type(uint256).max;
        }

        uint256 length = reserveList.length;
        uint256 accruedCollateral;

        for (uint256 i = 0; i < length; i++) {
            address asset = reserveList[i];
            // Reserve storage reserve = reserves[asset];
            uint256 balance = userBalance[user][asset];

            if (balance == 0) continue;
            uint256 threshold = reserves[asset].liquidationThreshold;
            accruedCollateral += (balance * threshold) / 10000;
        }
        uint256 healthFactor = (accruedCollateral * 1e18) / totalDebt_;
        return healthFactor;
    }

    function isLiquidatable(address user) public view returns (bool) {
        return calculateHealthFactor(user) < 1e18;
    }

    function liquidate(address user, address debtAsset, address collateralAsset, uint256 repayAmount)
        public
        nonReentrant
    {
        if (!isLiquidatable(user)) revert NotLiquidatable();
        if (repayAmount == 0) revert ZeroAmount();

        _requireInitialized(debtAsset);
        _requireInitialized(collateralAsset);

        uint256 debt = userDebt[user][debtAsset];

        uint256 maxRepay = debt <= 2 ? debt : debt / 2;

        if (repayAmount > maxRepay) {
            revert TooMuchPay();
        }

        uint256 actualRepay = repayAmount;

        IERC20(debtAsset).safeTransferFrom(msg.sender, address(this), actualRepay);

        userDebt[user][debtAsset] -= actualRepay;
        reserves[debtAsset].totalBorrowed -= actualRepay;

        DebtToken(reserves[debtAsset].debtToken).burn(user, actualRepay);

        uint256 bonus = reserves[collateralAsset].liquidationBonus;

        uint256 collateralToSeize = (actualRepay * (10000 + bonus)) / 10000;

        uint256 userCollateral = userBalance[user][collateralAsset];

        if (collateralToSeize > userCollateral) {
            collateralToSeize = userCollateral;
        }

        userBalance[user][collateralAsset] -= collateralToSeize;
        reserves[collateralAsset].totalDeposited -= collateralToSeize;

        AToken(reserves[collateralAsset].aToken).burn(user, collateralToSeize);

        IERC20(collateralAsset).safeTransfer(msg.sender, collateralToSeize);

        emit Liquidated(user, debtAsset, collateralAsset, actualRepay);
    }
}
