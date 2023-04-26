// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Faucet is Ownable {
    using SafeERC20 for IERC20;

    Pool[] public tokenPools;

    // user => pool => time
    mapping(address => mapping(uint => uint)) public requestTimes;

    struct Pool {
        address token;
        uint amountAllowed; 
    }

    event SendToken(
        address indexed token,
        address indexed receiver,
        uint indexed amount
    );

    constructor() {}

    function poolLength() external view returns (uint256) {
        return tokenPools.length;
    }

    function pools() external view returns (Pool[] memory) {
        return tokenPools;
    }

    function requestTokens(uint8 poolId) external {
        require(poolId >= 0 && poolId < tokenPools.length, "Invalid poolId");
        require(
            block.timestamp - requestTimes[msg.sender][poolId] > 1 days,
            "Only one request per day"
        );
        Pool memory pool = tokenPools[poolId];
        IERC20 token = IERC20(pool.token);
        require(
            token.balanceOf(address(this)) >= pool.amountAllowed,
            "Faucet Empty"
        );
        token.safeTransfer(msg.sender, pool.amountAllowed);
        requestTimes[msg.sender][poolId] = block.timestamp;
        emit SendToken(pool.token, msg.sender, pool.amountAllowed);
    }

    function addTokenPool(
        address _token,
        uint _amountAllowed
    ) external onlyOwner {
        require(_token != address(0), "token is zero address");
        tokenPools.push(Pool({token: _token, amountAllowed: _amountAllowed}));
    }

    function setTokenPool(
        uint8 poolId,
        address _token,
        uint _amountAllowed
    ) external onlyOwner {
        require(poolId >= 0 && poolId < tokenPools.length, "Invalid poolId");
        tokenPools[poolId].token = _token;
        tokenPools[poolId].amountAllowed = _amountAllowed;
    }

    function withdrawToken(address token, uint amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}
