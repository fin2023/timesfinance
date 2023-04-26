//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TimeLockTest is Ownable {
    address public account;

    constructor(address _account) {
        account = _account;
    }

    function changeAccount(address newAccount) external onlyOwner {
        account = newAccount;
    }
}
