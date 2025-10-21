// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MainVault} from "../src/BinanceLifeVault.sol";
import {BinanceLifePriceOracle} from "../src/BinanceLifePriceOracle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {MockToken} from "./mocks/MockToken.sol";
import {MockPair} from "./mocks/MockPair.sol";

contract EmergencySignTest is Test {
    MainVault public vault;
    BinanceLifePriceOracle public oracle;
    HelperConfig public helper;

    MockToken public lifeToken;
    HelperConfig.NetworkConfig public config;

    address public signerA;
    address public signerB;
    address public releaseAddress;

    function setUp() public {
        // 部署配置
        helper = new HelperConfig(30); // 目标价格 30 USDT
        config = helper.activeConfig();

        // 保存关键地址
        signerA = config.signerA;
        signerB = config.signerB;
        releaseAddress = config.releaseAddress;

        // 只部署必要的代币
        lifeToken = new MockToken("BinanceLife", "LIFE");
        MockToken wbnb = new MockToken("WBNB", "WBNB");
        MockToken usdt = new MockToken("USDT", "USDT");

        // 部署交易对
        MockPair lifeBnbPair = new MockPair(
            address(lifeToken),
            address(wbnb),
            1e18,
            0.05e18
        );
        MockPair bnbUsdtPair = new MockPair(
            address(wbnb),
            address(usdt),
            1e18,
            300e18
        );

        // 使用 vm.etch 覆盖配置地址
        vm.etch(config.binanceLifeToken, address(lifeToken).code);
        vm.etch(config.wbnb, address(wbnb).code);
        vm.etch(config.usdt, address(usdt).code);
        vm.etch(config.bnbUsdtPair, address(bnbUsdtPair).code);
        vm.etch(config.binanceLifeBnbPair, address(lifeBnbPair).code);

        // 部署合约
        oracle = new BinanceLifePriceOracle(helper);
        vault = new MainVault(helper);

        // 给保险库充值
        MockToken(config.binanceLifeToken).mint(address(vault), 1000 ether);
    }

    /// @notice 测试1: 双方都没有签名
    function test_NoSignersCannotWithdraw() public view {
        assertEq(vault.withdrawAllowed(), false, unicode"无签名时应该不能提款");
    }

    /// @notice 测试2: 只有A签名
    function test_OnlySignerACannotWithdraw() public {
        uint256 initialBalance = MockToken(config.binanceLifeToken).balanceOf(
            address(vault)
        );

        vm.prank(signerA);
        vault.emergencySign();

        assertEq(
            vault.withdrawAllowed(),
            false,
            unicode"只有A签名时应该不能提款"
        );
        assertEq(
            MockToken(config.binanceLifeToken).balanceOf(address(vault)),
            initialBalance,
            unicode"只有A签名时代币不应该转移"
        );
    }

    /// @notice 测试3: 只有B签名
    /// @notice 测试只有B签名
    function test_OnlySignerBCannotWithdraw() public {
        uint256 initialBalance = MockToken(config.binanceLifeToken).balanceOf(
            address(vault)
        );

        vm.prank(signerB);
        vault.emergencySign();

        assertEq(
            vault.withdrawAllowed(),
            false,
            unicode"只有B签名时应该不能提款"
        );
        assertEq(
            MockToken(config.binanceLifeToken).balanceOf(address(vault)),
            initialBalance,
            unicode"只有B签名时代币不应该转移"
        );
    }
    /// @notice 测试4: 双方都签名
    function test_BothSignersCanWithdraw() public {
        uint256 initialVaultBalance = MockToken(config.binanceLifeToken)
            .balanceOf(address(vault));
        uint256 initialReleaseBalance = MockToken(config.binanceLifeToken)
            .balanceOf(releaseAddress);

        // A签名
        vm.prank(signerA);
        vault.emergencySign();

        // B签名触发转移
        vm.prank(signerB);
        vault.emergencySign();

        assertEq(vault.withdrawAllowed(), true, unicode"双方签名后应该能提款");

        // 验证代币转移
        uint256 finalVaultBalance = MockToken(config.binanceLifeToken)
            .balanceOf(address(vault));
        uint256 finalReleaseBalance = MockToken(config.binanceLifeToken)
            .balanceOf(releaseAddress);

        assertEq(finalVaultBalance, 0, unicode"代币没有从保险库转出");
        assertEq(
            finalReleaseBalance,
            initialReleaseBalance + initialVaultBalance,
            unicode"代币没有转到释放地址"
        );
    }

    /// @notice 测试5: 非签名者调用无效
    function test_UnauthorizedSignerNoEffect() public {
        uint256 initialVaultBalance = MockToken(config.binanceLifeToken)
            .balanceOf(address(vault));
        uint256 initialReleaseBalance = MockToken(config.binanceLifeToken)
            .balanceOf(releaseAddress);

        address unauthorizedUser = makeAddr("hacker");
        vm.prank(unauthorizedUser);
        vm.expectRevert("Only signers can call this function");
        vault.emergencySign();

        // 验证状态完全没有改变
        assertEq(
            vault.emergencySignedByA(),
            false,
            unicode"非签名者调用后A签名状态改变了"
        );
        assertEq(
            vault.emergencySignedByB(),
            false,
            unicode"非签名者调用后B签名状态改变了"
        );
        assertEq(
            MockToken(config.binanceLifeToken).balanceOf(address(vault)),
            initialVaultBalance,
            unicode"非签名者调用后代币转移了"
        );
        assertEq(
            MockToken(config.binanceLifeToken).balanceOf(releaseAddress),
            initialReleaseBalance,
            unicode"非签名者调用后释放地址收到代币了"
        );
    }
}
