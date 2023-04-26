//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/universal-router/contracts/interfaces/IUniversalRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import "@uniswap/universal-router/contracts/libraries/Commands.sol";
import "../interfaces/external/INonfungiblePositionManager.sol";
import "../interfaces/strategy/IStrategyLiquidate.sol";
import "../token/IWETH.sol";
import "./LiquidityAmounts.sol";
import "./TickMath.sol";
import "../libiary/Constants.sol";

contract StrategyLiquidate is Ownable, ReentrancyGuard, IStrategyLiquidate, AccessControl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address payable;
    
    uint256 public bToken;

    IUniversalRouter router;

    bytes32 public constant LIQUIDATE_ROLE = keccak256("LIQUIDATE_ROLE");

    modifier onlyGovernor() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "StrategyLiquidate: caller is not the governor"
        );
        _;
    }

    modifier onlyLiquidater() {
        require(
            hasRole(LIQUIDATE_ROLE, msg.sender),
            "StrategyLiquidate: caller is not the liquidater"
        );
        _;
    }


    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        router = IUniversalRouter(Constants.UniversalRouter);
    }

    function grantLiquidater(address liquidater) public onlyGovernor {  
        _setupRole(LIQUIDATE_ROLE, liquidater);
    }

    function revokeLiquidater(address liquidater) public onlyGovernor {
        revokeRole(LIQUIDATE_ROLE, liquidater);
    }

    function execute(uint256 tokenId, address borrowToken, bytes calldata data)
        override
        external
        payable
        nonReentrant
        onlyLiquidater
    {
        (,,address token0, address token1,,,,,,,,) = INonfungiblePositionManager(Constants.NonfungiblePositionManager).positions(tokenId);


        (, bytes memory ext) = abi.decode(data,(address, bytes));

        (,,,,,, uint24 fee) = abi.decode(ext, (address, address, uint256, uint256, int24, int24, uint24));
        
        require(borrowToken == token0 || borrowToken == token1, "borrowToken not token0 and token1");
        
        {
            uint128 liquidity = getLiquidity(tokenId);

            INonfungiblePositionManager(Constants.NonfungiblePositionManager).decreaseLiquidity(
                INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            }));

            INonfungiblePositionManager(Constants.NonfungiblePositionManager).collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId: tokenId,
                    recipient: address(this),  
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            );

            liquidity = getLiquidity(tokenId);

            if (liquidity == uint128(0)) {
                INonfungiblePositionManager(Constants.NonfungiblePositionManager).burn(tokenId);
            }
        }

        address tokenRelative = borrowToken == token0 ? token1 : token0;

        address[] memory path = new address[](2);
        (path[0], path[1]) = (tokenRelative, borrowToken);

        IERC20(path[0]).safeApprove(address(this), 0);
        IERC20(path[0]).safeApprove(
            address(this),
            IERC20(path[0]).balanceOf(address(this))
        );
        IERC20(path[0]).safeTransferFrom(
            address(this),
            address(router),
            IERC20(path[0]).balanceOf(address(this))
        );

        address recep = address(1);

        bytes[] memory datas = new bytes[](1);

        bytes memory commands = abi.encodePacked(
            bytes1(uint8(Commands.V3_SWAP_EXACT_IN))
        );

        datas[0] = abi.encode(
            recep,
            IERC20(path[0]).balanceOf(address(this)),
            0,
            abi.encodePacked(path[0], fee, path[1]),
            false
        );

        router.execute(commands, datas);

        IERC20(borrowToken).safeTransfer(msg.sender, IERC20(borrowToken).balanceOf(address(this)));
    }

    function updateBorrowTokenAmount(uint256 tokenId, address borrowToken) override external   {
        (,,address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity,,,,) = INonfungiblePositionManager(Constants.NonfungiblePositionManager).positions(tokenId);
        borrowToken = borrowToken == address(0) ? Constants.WETH : borrowToken;
        require(borrowToken == token0 || borrowToken == token1, "borrowToken not token0 and token1");

        address pool = IUniswapV3Factory(Constants.V3Factory).getPool(
            token0,        
            token1,           
            fee
        );

        (uint256 debtReserve, uint256 relativeReserve) = getReserve(pool, borrowToken, tickLower, tickUpper, liquidity);

        address tokenIn = borrowToken == token0 ? token1 : token0;

        IQuoterV2.QuoteExactInputSingleParams memory params = IQuoterV2
            .QuoteExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: borrowToken,
                amountIn: relativeReserve,
                fee: fee,
                sqrtPriceLimitX96: 0
            });
        (uint256 amountOut, , , ) = IQuoterV2(Constants.Quoter).quoteExactInputSingle(
            params
        );
        
        uint256 borrowAmount = debtReserve + amountOut;
        bToken = borrowAmount;
    }

    function getBorrowTokenAmount() override external view returns (uint256)  {
        return bToken;
    }

    function getReserve(address pool, address borrowToken, int24 tickLower, int24 tickUpper, uint128 liquidity) public view returns(uint256 debtReserve, uint256 relativeReserve) {
        (uint160 sqrtRatioX96, , , , , , ) = IUniswapV3Pool(pool).slot0();

        (uint256 token0Reserve, uint256 token1Reserve) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            liquidity
        );

        (debtReserve, relativeReserve) = borrowToken ==
            IUniswapV3Pool(pool).token0() ? (token0Reserve, token1Reserve) : (token1Reserve, token0Reserve);
    }

    function getLiquidity(uint256 tokenId) public view returns (uint128 liquidity) {
        ( , , , , , , , liquidity, , , , ) = INonfungiblePositionManager(Constants.NonfungiblePositionManager).positions(tokenId);
    }


    function recover(address token, address to, uint256 value) external onlyOwner nonReentrant {
        IERC20(token).safeTransfer(to, value);
    }

    receive() external payable {}
}