// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AToken} from "src/active/myTokens/aToken.sol";
import {DebtToken} from "src/active/myTokens/debtToken.sol";

/// tomi think you want to do something that if the amount being repayed is greater than the userDebt of then the excess play amount should flow to the totaldeposited
contract MyMiniAave {
    mapping(address => uint256) userBalance;

    mapping(address => uint256) userDebt;
    // or instead address(this) it should be like uint256 but then wo but this just mapp what every user deposited to the conntract kini sha
    // i thinking there should be something mapping (address(this) => mapping(address => uint256) userBalance ) totalDeposited;
    // and do this for debt too

    uint256 public totalDeposited;
    uint256 public totalDebt;

    AToken public aToken;
    DebtToken public debtToken;

    // ERC20 immutable token;

    // DO I NEED TO TRACK TOKEN BALANCE OR THAT IS DONE BY THE TOKEN CONTRACT
    constructor(address _aToken, address _debtToken) {
        aToken = AToken(_aToken);
        debtToken = DebtToken(_debtToken);
    }
    // mapping(address _token => uint256 ) amount of token mintetd
    error cannotDepositZero();
    error depositFailed();
    error insufficientbalance();
    error withdrawalFailed();
    error CannotBorrowZero();
    error BorrowNotSuccessful();
    error CannotRepayNothing();
    error CannotPayMoreThanOwe();

    event deposited(address indexed user, uint256 indexed amount);
    event withdrawed(address indexed user, uint256 indexed amount);

    function deposit(uint256 amount, address asset) public returns (bool) {
        // uint256 userInitialBalance = userBalance[msg.sender];
        if (amount == 0) {
            revert cannotDepositZero();
        }

        bool success = IERC20(asset).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert withdrawalFailed();
        }
        aToken.mint(msg.sender, amount);
        userBalance[msg.sender] += amount;
        // ERC20(token).mint(msg.sender, amount); // not sure

        totalDeposited += amount;
        emit deposited(msg.sender, amount);
        return success;
    }

    function withdraw(uint256 amount, address asset) public returns (bool) {
        // uint256 userInitialBalance = userBalance[msg.sender];
        if (userBalance[msg.sender] < amount) {
            revert insufficientbalance();
        }
        bool success = IERC20(asset).transfer(msg.sender, amount);
        if (!success) {
            revert withdrawalFailed();
        }
        aToken.burn(msg.sender, amount);
        // ERC20(token).burn(msg.sender, amount); // not sure  YOU ARE SUPPOSE TO BURN THE MINTED TOKEN  edited now it is asking whoose person TOKEN BALANCR AM I MINTING
        userBalance[msg.sender] -= amount;
        totalDeposited -= amount;

        emit withdrawed(msg.sender, amount);
        return success;
    }

    function borrow(address asset, uint256 amount) public {
        if (amount == 0) {
            revert CannotBorrowZero();
        }

        if (userBalance[msg.sender] < amount) {
            revert insufficientbalance();
        }
        bool success = IERC20(asset).transfer(msg.sender, amount);
        if (!success) {
            revert BorrowNotSuccessful();
        }
        debtToken.mint(msg.sender, amount);
        totalDebt += amount;
        totalDeposited -= amount;
        userBalance[msg.sender] -= amount;
        userDebt[msg.sender] += amount;
    }

    function repay(address asset, uint256 amount) public {
        if (amount == 0) {
            revert CannotRepayNothing();
        }
        // so remeber you ideaa this just a jam
        if (amount > userDebt[msg.sender]) {
            revert CannotPayMoreThanOwe();
        }
        IERC20(asset).transferFrom(msg.sender, address(this), amount);

        debtToken.burn(msg.sender, amount);
        
        // totalDeposited -= amount; // we are going to ADD SOMETHING LIKE THIS TO FLOW TO TOTALDEPOSITED
        // userBalance[msg.sender] -= amount;  BOTH LINES
        totalDebt -= amount; // WHAT IS THE CORREECT OTHER FOR THIS
        userDebt[msg.sender] -= amount;
    }

    function getBalance(address user) public view returns (uint256) {
        uint256 balanceOfUser = userBalance[user];
        return balanceOfUser;
    }
}
