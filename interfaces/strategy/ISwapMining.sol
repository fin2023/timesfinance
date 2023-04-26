//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * Interface of SwapMining contract.
 */

interface ISwapMining {

    /// The user withdraws all the transaction rewards of the pool
    function takerWithdraw() external;

    /// Get rewards from users in the current pool
    /// @param pid pid of pair.
    function getUserReward(uint256 pid) external view returns (uint256, uint256);

}