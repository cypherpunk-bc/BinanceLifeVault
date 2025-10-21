// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract HelperConfigTest is Test {
    HelperConfig helper;

    function setUp() public {
        // 初始化 HelperConfig，targetPrice = 100
        helper = new HelperConfig(100);
    }

    function testActiveConfigMainnet() public {
        // 模拟主网链id
        vm.chainId(56);
        helper = new HelperConfig(100);
        HelperConfig.NetworkConfig memory config = helper.activeConfig();

        // 验证地址
        assertEq(
            config.binanceLifeToken,
            0x924fa68a0FC644485b8df8AbfA0A41C2e7744444
        );
        assertEq(config.wbnb, 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        assertEq(config.usdt, 0x55d398326f99059fF775485246999027B3197955);

        // 验证 targetPrice 是否放大 1e18
        assertEq(config.targetPrice, 100 * 1e18);
    }

    function testActiveConfigLocal() public view {
        // 本地测试，链id不是 56 或 97
        if (block.chainid == 56 || block.chainid == 97) {
            return;
        }

        HelperConfig.NetworkConfig memory config = helper.activeConfig();

        // 验证占位地址
        assertEq(config.binanceLifeToken, address(0x333));
        assertEq(config.wbnb, address(0x111));
        assertEq(config.usdt, address(0x222));

        // 验证 targetPrice 是否放大 1e18
        assertEq(config.targetPrice, 100 * 1e18);
    }
}
