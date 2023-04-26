//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IWorker {

    /// @dev 开仓
    function openPosition(
        uint256 positionId,
        address user,
        address borrowToken,
        uint256 borrow,
        bytes calldata data
    ) external payable returns (uint256);

    /// @dev 关仓
    function closePosition(
        uint256 positionId,
        address user,
        address borrowToken,
        uint256 borrow,
        bytes calldata data
    ) external payable;

    /// @dev Return the amount of ETH wei to get back if we are to liquidate the position.
    function health()
        external
        view
        returns (uint256);
    function updateHealth(uint256 id, address borrowToken) external;
    /// @dev Liquidate the given position to token need. Send all ETH back to Bank.
    function liquidate(
        uint256 id,
        address user,
        address borrowToken,
        bytes calldata data
    ) external;
}
