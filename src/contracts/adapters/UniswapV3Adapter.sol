//       ╟╗                                                                      ╔╬
//       ╞╬╬                                                                    ╬╠╬
//      ╔╣╬╬╬                                                                  ╠╠╠╠╦
//     ╬╬╬╬╬╩                                                                  ╘╠╠╠╠╬
//    ║╬╬╬╬╬                                                                    ╘╠╠╠╠╬
//    ╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬      ╒╬╬╬╬╬╬╬╜   ╠╠╬╬╬╬╬╬╬         ╠╬╬╬╬╬╬╬    ╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠
//    ╙╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╕    ╬╬╬╬╬╬╬╜   ╣╠╠╬╬╬╬╬╬╬╬        ╠╬╬╬╬╬╬╬   ╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╩
//     ╙╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬  ╔╬╬╬╬╬╬╬    ╔╠╠╠╬╬╬╬╬╬╬╬        ╠╬╬╬╬╬╬╬ ╣╬╬╬╬╬╬╬╬╬╬╬╠╠╠╠╝╙
//               ╘╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬    ╒╠╠╠╬╠╬╩╬╬╬╬╬╬       ╠╬╬╬╬╬╬╬╣╬╬╬╬╬╬╬╙
//                 ╣╬╬╬╬╬╬╬╬╬╬╠╣     ╣╬╠╠╠╬╩ ╚╬╬╬╬╬╬      ╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬
//                  ╣╬╬╬╬╬╬╬╬╬╣     ╣╬╠╠╠╬╬   ╣╬╬╬╬╬╬     ╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬
//                   ╟╬╬╬╬╬╬╬╩      ╬╬╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬     ╠╬╬╬╬╬╬╬╠╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬     ╒╬╬╠╠╬╠╠╬╬╬╬╬╬╬╬╬╬╬╬    ╠╬╬╬╬╬╬╬ ╣╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬     ╬╬╬╠╠╠╠╝╝╝╝╝╝╝╠╬╬╬╬╬╬   ╠╬╬╬╬╬╬╬  ╚╬╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬    ╣╬╬╬╬╠╠╩       ╘╬╬╬╬╬╬╬  ╠╬╬╬╬╬╬╬   ╙╬╬╬╬╬╬╬╬
//

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../interface/IERC20.sol";
import "../lib/SafeERC20.sol";
import "../YakAdapter.sol";

struct QParams {
    address tokenIn;
    address tokenOut;
    int256 amountIn;
    uint24 fee;
}

interface IUniV3Factory {
    function feeAmountTickSpacing(uint24) external view returns (int24);

    function getPool(
        address,
        address,
        uint24
    ) external view returns (address);
}

interface IUniV3Pool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function liquidity() external view returns (uint128);
}

interface IUniV3Quoter {
    function quoteExactInputSingle(QParams memory params) external view returns (uint256);

    function quote(
        address,
        bool,
        int256,
        uint160
    ) external view returns (int256, int256);
}

contract UniswapV3Adapter is YakAdapter {
    using SafeERC20 for IERC20;

    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    address immutable FACTORY;
    address immutable QUOTER;
    mapping(address => mapping(address => uint256[])) paths;
    mapping(uint24 => bool) public isFeeAmountEnabled;
    uint24[] public feeAmounts;

    constructor(
        string memory _name,
        address _factory,
        address _quoter,
        uint256 _swapGasEstimate
    ) YakAdapter(_name, _swapGasEstimate) {
        addDefaultFeeAmounts();
        FACTORY = _factory;
        QUOTER = _quoter;
    }

    function addDefaultFeeAmounts() internal {
        addFeeAmount(500);
        addFeeAmount(3000);
        addFeeAmount(10000);
    }

    function enableFeeAmounts(uint24[] calldata _amounts) external onlyMaintainer {
        for (uint256 i; i < _amounts.length; ++i) enableFeeAmount(_amounts[i]);
    }

    function getQuoteForPool(
        address pool,
        int256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256) {
        QParams memory params;
        params.amountIn = amountIn;
        params.tokenIn = tokenIn;
        params.tokenOut = tokenOut;
        return getQuoteForPool(pool, params);
    }

    function enableFeeAmount(uint24 _fee) internal {
        require(!isFeeAmountEnabled[_fee], "Fee already enabled");
        if (IUniV3Factory(FACTORY).feeAmountTickSpacing(_fee) == 0) revert("Factory doesn't support fee");
        addFeeAmount(_fee);
    }

    function addFeeAmount(uint24 _fee) internal {
        isFeeAmountEnabled[_fee] = true;
        feeAmounts.push(_fee);
    }

    function _query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) internal view override returns (uint256 quote) {
        QParams memory params = getQParams(_amountIn, _tokenIn, _tokenOut);
        quote = getQuoteForMostLiquidPool(params);
    }

    function getQParams(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) internal pure returns (QParams memory params) {
        params = QParams({ tokenIn: tokenIn, tokenOut: tokenOut, amountIn: int256(amountIn), fee: 0 });
    }

    function getQuoteForMostLiquidPool(
        QParams memory params
    ) internal view returns (uint256 quote) {
        address mostLiquidPool = getMostLiquidPool(params.tokenIn, params.tokenOut);
        quote = getQuoteForPool(mostLiquidPool, params);
    }

    function getMostLiquidPool(
        address token0, 
        address token1
    ) internal view returns (address mostLiquid) {
        uint128 deepestLiquidity;
        for (uint256 i; i < feeAmounts.length; ++i) {
            address pool = IUniV3Factory(FACTORY).getPool(token0, token1, feeAmounts[i]);
            if (pool == address(0))
                continue;
            uint128 liquidity = IUniV3Pool(pool).liquidity();
            if (liquidity > deepestLiquidity) {
                deepestLiquidity = liquidity;
                mostLiquid = pool;
            }
        }
    } 

    function getQuoteForPool(address pool, QParams memory params) internal view returns (uint256) {
        (bool zeroForOne, uint160 priceLimit) = getZeroOneAndSqrtPriceLimitX96(params.tokenIn, params.tokenOut);
        (int256 amount0, int256 amount1) = IUniV3Quoter(QUOTER).quote(pool, zeroForOne, params.amountIn, priceLimit);
        return zeroForOne ? uint256(-amount1) : uint256(-amount0);
    }

    function getZeroOneAndSqrtPriceLimitX96(address tokenIn, address tokenOut)
        internal
        pure
        returns (bool zeroForOne, uint160 sqrtPriceLimitX96)
    {
        zeroForOne = tokenIn < tokenOut;
        sqrtPriceLimitX96 = zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1;
    }

    function _swap(
        uint256 _amountIn,
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut,
        address _to
    ) internal override {
        QParams memory params = getQParams(_amountIn, _tokenIn, _tokenOut);
        uint256 amountOut = _underlyingSwap(params, new bytes(0));
        require(amountOut >= _amountOut, "Insufficient amountOut");
        _returnTo(_tokenOut, amountOut, _to);
    }

    function _underlyingSwap(QParams memory params, bytes memory callbackData) internal returns (uint256) {
        address pool = getMostLiquidPool(params.tokenIn, params.tokenOut);
        (bool zeroForOne, uint160 sqrtPriceLimitX96) = getZeroOneAndSqrtPriceLimitX96(params.tokenIn, params.tokenOut);
        (int256 amount0, int256 amount1) = IUniV3Pool(pool).swap(
            address(this),
            zeroForOne,
            int256(params.amountIn),
            sqrtPriceLimitX96,
            callbackData
        );
        return zeroForOne ? uint256(-amount1) : uint256(-amount0);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external {
        if (amount0Delta > 0) {
            IERC20(IUniV3Pool(msg.sender).token0()).transfer(msg.sender, uint256(amount0Delta));
        } else {
            IERC20(IUniV3Pool(msg.sender).token1()).transfer(msg.sender, uint256(amount1Delta));
        }
    }

    function decodeCallbackData(bytes memory data) internal pure returns (address trader, uint256 minAmountOut) {
        assembly {
            trader := mload(add(data, 0x14))
            minAmountOut := mload(add(data, 0x34))
        }
    }
}
