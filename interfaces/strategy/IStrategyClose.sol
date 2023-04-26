//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IStrategyClose {

    function execute(
        address user,
        address borrowToken,
        uint256 debt,
        uint256 tokenId,
        bytes calldata data
    ) external payable;
}
