// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MainVault} from "../src/BinanceLifeVault.sol";
import {BinanceLifePriceOracle} from "../src/BinanceLifePriceOracle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

// 导入MockToken
import {MockToken} from "./mocks/MockToken.sol";

// 使用MockPair
import {MockPair} from "./mocks/MockPair.sol";

contract MainVaultTest is Test {
    MainVault vault;
    BinanceLifePriceOracle oracle;
    HelperConfig helper;

    MockToken lifeToken;
    MockToken wbnb;
    MockToken usdt;

    address User = makeAddr("User");

    HelperConfig.NetworkConfig config;

    function setUp() public {
        helper = new HelperConfig(30);
        config = helper.activeConfig();

        // 部署 MockToken
        lifeToken = new MockToken("BinanceLife", "LIFE");
        wbnb = new MockToken("WBNB", "WBNB");
        usdt = new MockToken("USDT", "USDT");

        // 部署临时的 MockPair 实例来获取字节码
        MockPair tempLifeBnbPair = new MockPair(
            address(lifeToken),
            address(wbnb),
            1e18,
            0.1e18 // 初始储备量
        );
        MockPair tempBnbUsdtPair = new MockPair(
            address(wbnb),
            address(usdt),
            1e18,
            300e18
        );

        // 使用 vm.etch 让配置地址变成真实合约
        vm.etch(config.binanceLifeToken, address(lifeToken).code);
        vm.etch(config.wbnb, address(wbnb).code);
        vm.etch(config.usdt, address(usdt).code);
        vm.etch(config.bnbUsdtPair, address(tempBnbUsdtPair).code);
        vm.etch(config.binanceLifeBnbPair, address(tempLifeBnbPair).code);

        // 初始化配置地址的储备量
        MockPair(config.binanceLifeBnbPair).setReserves(1e18, 0.1e18);
        MockPair(config.bnbUsdtPair).setReserves(1e18, 300e18);

        oracle = new BinanceLifePriceOracle(helper);
        vault = new MainVault(helper);

        // 给 Vault 打 LIFE Token
        MockToken(config.binanceLifeToken).mint(address(vault), 1000 ether);
    }

    /// @notice 测试正常存款
    function testDeposit() public {
        address user = makeAddr("user");
        uint256 depositAmount = 500 ether;

        // 给用户代币
        MockToken(config.binanceLifeToken).mint(user, depositAmount);

        // 用户先授权，再存款
        vm.prank(user);
        MockToken(config.binanceLifeToken).approve(
            address(vault),
            depositAmount
        );

        vm.prank(user);
        vault.deposit(depositAmount);

        // 验证余额变化
        assertEq(
            MockToken(config.binanceLifeToken).balanceOf(address(vault)),
            1000 ether + depositAmount
        );
        assertEq(MockToken(config.binanceLifeToken).balanceOf(user), 0);
    }

    function testRelease() public {
        assertEq(
            MockToken(config.binanceLifeToken).balanceOf(address(vault)),
            1000 ether
        );

        // Vault 自己调用释放
        vm.prank(address(vault));
        vault.checkAndRelease();

        assertEq(
            MockToken(config.binanceLifeToken).balanceOf(config.releaseAddress),
            1000 ether
        );
    }

    function testPriceTrigger() public {
        // 🔥 关键修改：直接通过配置地址设置储备量
        MockPair(config.binanceLifeBnbPair).setReserves(1e18, 0.2e18); // 1 LIFE = 0.2 BNB

        uint256 price = oracle.getPrice();
        console.log("Simulated LIFE/USDT price:", price / 1e18); // 现在应该输出 60 USDT

        // 添加断言验证
        assertEq(price / 1e18, 60, "Price should be 60 USDT");
    }

    function testGetPrice() public view {
        uint256 price = oracle.getPrice();
        console.log("Current LIFE/USDT price:", price / 1e18);
    }

    function testGetContractBalance() public view {
        uint256 balance = MockToken(config.binanceLifeToken).balanceOf(
            address(vault)
        );
        console.log("Vault LIFE balance:", balance / 1e18);
    }
}
