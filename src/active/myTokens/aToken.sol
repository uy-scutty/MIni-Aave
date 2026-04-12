// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AToken is ERC20 {
    error AToken___OnlyPoolContractCanMintOrBurnToken();
    address public mainPool;

    constructor(uint256 initialSupply, address _mainPool) ERC20("aToken", "ATK") {
        _mint(msg.sender, initialSupply);
        mainPool = _mainPool;
    }
    modifier onlyCaller() {
        if (msg.sender != mainPool) {
            revert AToken___OnlyPoolContractCanMintOrBurnToken();
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
