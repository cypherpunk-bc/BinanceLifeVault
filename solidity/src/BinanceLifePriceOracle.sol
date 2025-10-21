// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {HelperConfig} from "../script/HelperConfig.s.sol";

interface IPancakePair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

/// @title BinanceLifePriceOracle
/// @notice 从 PancakeSwap 获取 BinanceLife 代币的实时价格
/// @dev 通过 LIFE/BNB 和 BNB/USDT 交易对计算 LIFE/USDT 价格
contract BinanceLifePriceOracle {
    address public immutable BINANCELIFE_TOKEN;
    address public immutable WBNB;
    address public immutable USDT;
    address public immutable BNB_USDT_PAIR;
    address public immutable BINANCELIFE_BNB_PAIR;

    //
    constructor(
        address binanceLifeToken,
        address wbnb,
        address usdt,
        address bnbUsdtPair,
        address binanceLifeBnbPair
    ) {
        BINANCELIFE_TOKEN = binanceLifeToken;
        WBNB = wbnb;
        USDT = usdt;
        BNB_USDT_PAIR = bnbUsdtPair;
        BINANCELIFE_BNB_PAIR = binanceLifeBnbPair;
    }

    /// @notice 获取 BinanceLife 代币的当前价格（以 USDT 计价，放大 1e18）
    /// @return price LIFE/USDT 价格，放大 1e18
    function getPrice() external view returns (uint256 price) {
        // 1. 获取 BNB 价格（USDT）
        uint256 bnbPrice = getTokenPrice(BNB_USDT_PAIR, WBNB, USDT);

        // 2. 获取 LIFE 价格（BNB）
        uint256 lifePriceInBnb = getTokenPrice(
            BINANCELIFE_BNB_PAIR,
            BINANCELIFE_TOKEN,
            WBNB
        );

        // 3. 计算最终价格：LIFE/USDT = LIFE/BNB × BNB/USDT
        price = (lifePriceInBnb * bnbPrice) / 1e18;
    }

    /// @notice 从交易对获取 tokenA 相对于 tokenB 的价格
    /// @param pair 交易对地址
    /// @param tokenA 基础代币
    /// @param tokenB 计价代币
    /// @return price tokenA/tokenB 价格，放大 1e18
    function getTokenPrice(
        address pair,
        address tokenA,
        address tokenB
    ) public view returns (uint256 price) {
        // 获取交易对储备量和代币信息
        (uint112 reserve0, uint112 reserve1, ) = IPancakePair(pair)
            .getReserves();
        address token0 = IPancakePair(pair).token0();
        address token1 = IPancakePair(pair).token1();

        // 验证交易对包含正确的代币
        require(
            (token0 == tokenA && token1 == tokenB) ||
                (token0 == tokenB && token1 == tokenA),
            "BinanceLifePriceOracle: INVALID_PAIR"
        );

        // 根据代币顺序计算价格
        if (token0 == tokenA) {
            // token0 = tokenA, token1 = tokenB
            // 价格 = reserve1 / reserve0 (tokenB per tokenA)
            price = (uint256(reserve1) * 1e18) / reserve0;
        } else {
            // token0 = tokenB, token1 = tokenA
            // 价格 = reserve0 / reserve1 (tokenB per tokenA)
            price = (uint256(reserve0) * 1e18) / reserve1;
        }
    }

    /// @notice 获取所有相关价格信息（用于调试）
    /// @return bnbPrice BNB/USDT 价格
    /// @return lifePriceInBnb LIFE/BNB 价格
    /// @return lifePriceInUsdt LIFE/USDT 价格
    function getPriceDetails()
        external
        view
        returns (
            uint256 bnbPrice,
            uint256 lifePriceInBnb,
            uint256 lifePriceInUsdt
        )
    {
        bnbPrice = getTokenPrice(BNB_USDT_PAIR, WBNB, USDT);
        lifePriceInBnb = getTokenPrice(
            BINANCELIFE_BNB_PAIR,
            BINANCELIFE_TOKEN,
            WBNB
        );
        lifePriceInUsdt = (lifePriceInBnb * bnbPrice) / 1e18;
    }
}
