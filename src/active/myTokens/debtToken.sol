// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DebtToken is ERC20 {
    error DebtToken___OnlyPoolContractCanMintOrBurnToken();
    address public mainPool;

    constructor(uint256 initialSupply) ERC20("debtToken", "DBT") {
        _mint(msg.sender, initialSupply);
    }
    modifier onlyCaller() {
        if (msg.sender != mainPool) {
            revert DebtToken___OnlyPoolContractCanMintOrBurnToken();
            _;
        }
    }

    function mint(address to, uint256 value) external onlyCaller {
        _mint(to, value);
    }

    function burn(address from, uint256 value) external onlyCaller {
        _burn(from, value);
    }
}
