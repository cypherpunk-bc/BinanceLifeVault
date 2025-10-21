// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {BinanceLifePriceOracle} from "../src/BinanceLifePriceOracle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {MockPair} from "./mocks/MockPair.sol";

contract BinanceLifePriceOracleTest is Test {
    HelperConfig helper;
    BinanceLifePriceOracle oracle;

    function setUp() public {
        // 部署 HelperConfig，本地环境会自动创建 MockPair
        helper = new HelperConfig(100);

        // 部署价格合约
        oracle = new BinanceLifePriceOracle(helper);
    }

    function testPriceCalculation() public view {
        uint256 price = oracle.getPrice();

        console.log("Simulated LIFE/USDT price:", price / 1e18);

        // 模拟价格应为 30 USDT
        assertEq(price, 30 * 1e18);
    }

    function testPriceAfterChangingMock() public {
        // 获取本地的 mock pair
        HelperConfig.NetworkConfig memory config = helper.activeConfig();

        MockPair lifeBnbPair = MockPair(config.binanceLifeBnbPair);
        MockPair bnbUsdtPair = MockPair(config.bnbUsdtPair);

        // 改变储备量，模拟 LIFE / BNB 涨价
        lifeBnbPair.setReserves(1e18, 0.2e18); // 1 LIFE = 0.2 BNB
        bnbUsdtPair.setReserves(1e18, 300e18); // BNB / USDT 不变

        uint256 newPrice = oracle.getPrice();

        console.log("New simulated LIFE/USDT price:", newPrice / 1e18);

        // 新价格应为 0.2 * 300 = 60 USDT
        assertEq(newPrice, 60 * 1e18);
    }
}
