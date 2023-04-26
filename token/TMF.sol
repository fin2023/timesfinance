//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TMF is ERC20("Times Finance Coin", "TMF") {
    
    constructor() {
        _mint(msg.sender,1e26);
    }
    
}