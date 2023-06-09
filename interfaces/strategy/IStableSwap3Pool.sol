//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

// 0: DAI, 1: USDC, 2: USDT
interface IStableSwap3Pool {
    function get_virtual_price() external view returns (uint);
    function balances(uint) external view returns (uint);
    function calc_token_amount(uint[3] calldata amounts, bool deposit) external view returns (uint);
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);
    function get_dy(int128 i, int128 j, uint dx) external view returns (uint);
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_amount) external;
    function exchange(int128 i, int128 j, uint dx, uint min_dy) external;
        
    function add_liquidity(uint[3] calldata amounts, uint min_mint_amount) external returns (uint256);
    function remove_liquidity(uint256 _amount, uint[3] calldata min_amounts) external returns (uint256);
}
