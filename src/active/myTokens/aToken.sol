// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AToken is ERC20 {
    address public immutable mainPool;

    error OnlyPool();

    constructor(string memory name_, string memory symbol_, address pool_) ERC20(name_, symbol_) {
        mainPool = pool_;
    }

    modifier onlyPool() {
        if (msg.sender != mainPool) revert OnlyPool();
        _;
    }

    function mint(address to, uint256 amount) external onlyPool {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyPool {
        _burn(from, amount);
    }
}
