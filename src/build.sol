// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract build {
    mapping(address => uint256) userBalance;
    uint256 public totalDeposited;

    error cannotDepositZero();
    error depositFailed();
    error insufficientbalance();
    error withdrawalFailed();

    event deposited(address indexed user, uint256 indexed amount);
    event withdrawed(address indexed user, uint256 indexed amount);

    function deposit(uint256 amount, address asset) public returns (bool) {
        // uint256 userInitialBalance = userBalance[msg.sender];
        if (amount == 0) {
            revert cannotDepositZero();
        }
        IERC20(asset).approve(address(this), amount);
        bool success = IERC20(asset).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert depositFailed();
        }
        userBalance[msg.sender] += amount;
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
        userBalance[msg.sender] -= amount;
        totalDeposited -= amount;
        emit withdrawed(msg.sender, amount);
        return success;
    }

    function getBalance(address user) public view returns (uint256) {
        uint256 balanceOfUser = userBalance[user];
        return balanceOfUser;
    }
}
