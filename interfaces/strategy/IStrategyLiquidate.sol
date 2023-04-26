//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IStrategyLiquidate {
    function execute(uint256 tokenId, address borrowToken, bytes calldata data) external payable;

    function getBorrowTokenAmount() external view returns (uint256);

    function updateBorrowTokenAmount(uint256 tokenId, address borrowToken) external;
}
