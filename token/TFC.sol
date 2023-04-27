//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TFC is ERC20("Times Finance Coin", "TFC") {
    
    constructor() {
        _mint(msg.sender,1e26);
    }
    
}
