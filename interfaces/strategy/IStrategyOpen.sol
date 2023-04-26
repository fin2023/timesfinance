//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IStrategyOpen {

    function execute(
        address user,
        address borrowToken,
        uint256 borrow,
        bytes calldata data
    ) external payable returns (uint256);
}
