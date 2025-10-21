// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MainVault} from "../src/BinanceLifeVault.sol";
import {BinanceLifePriceOracle} from "../src/BinanceLifePriceOracle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {MockToken} from "./mocks/MockToken.sol";
import {MockPair} from "./mocks/MockPair.sol";

contract ChainlinkAutomationTest is Test {
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

    /// @notice 测试价格未达到目标时 checkUpkeep 返回 false
    function test_CheckUpkeep_WhenPriceNotReached() public {
        // 设置低价，确保不触发条件
        MockPair(config.binanceLifeBnbPair).setReserves(1e18, 0.05e18); // 1 LIFE = 0.05 BNB = 15 USDT

        (bool upkeepNeeded, bytes memory performData) = vault.checkUpkeep("");

        assertEq(
            upkeepNeeded,
            false,
            unicode"价格未达到时应该不需要执行upkeep"
        );
        assertEq(performData.length, 0, unicode"不需要执行时应该返回空数据");
    }

    /// @notice 测试价格达到目标时 checkUpkeep 返回 true
    function test_CheckUpkeep_WhenPriceReached() public {
        // 设置价格达到目标（30 USDT）
        MockPair(config.binanceLifeBnbPair).setReserves(1e18, 0.1e18); // 1 LIFE = 0.1 BNB = 30 USDT

        (bool upkeepNeeded, bytes memory performData) = vault.checkUpkeep("");

        assertEq(upkeepNeeded, true, unicode"价格达到目标时应该需要执行upkeep");
        assertEq(performData.length, 0, unicode"执行数据应该为空");
    }

    /// @notice 测试已允许提款时 checkUpkeep 返回 false
    function test_CheckUpkeep_WhenWithdrawAlreadyAllowed() public {
        // 先通过紧急签名允许提款
        vm.prank(signerA);
        vault.emergencySign();
        vm.prank(signerB);
        vault.emergencySign();

        // 即使价格达到，也应该返回 false（因为已经允许提款）
        MockPair(config.binanceLifeBnbPair).setReserves(1e18, 0.1e18);

        (bool upkeepNeeded, bytes memory performData) = vault.checkUpkeep("");

        assertEq(
            upkeepNeeded,
            false,
            unicode"已允许提款时不应该需要执行upkeep"
        );
        assertEq(performData.length, 0, unicode"执行数据应该为空");
    }

    /// @notice 测试 performUpkeep 成功执行价格触发释放
    function test_PerformUpkeep_Success() public {
        // 设置价格达到目标
        MockPair(config.binanceLifeBnbPair).setReserves(1e18, 0.1e18);

        uint256 initialVaultBalance = MockToken(config.binanceLifeToken)
            .balanceOf(address(vault));
        uint256 initialReleaseBalance = MockToken(config.binanceLifeToken)
            .balanceOf(releaseAddress);

        console.log(unicode"执行前 - 保险库余额:", initialVaultBalance);
        console.log(unicode"执行前 - 释放地址余额:", initialReleaseBalance);

        // 执行自动化任务
        vault.performUpkeep("");

        // 验证状态
        assertEq(vault.released(), true, unicode"执行后应该标记为已释放");
        assertEq(vault.withdrawAllowed(), true, unicode"执行后应该允许提款");

        // 验证代币转移
        uint256 finalVaultBalance = MockToken(config.binanceLifeToken)
            .balanceOf(address(vault));
        uint256 finalReleaseBalance = MockToken(config.binanceLifeToken)
            .balanceOf(releaseAddress);

        console.log(unicode"执行后 - 保险库余额:", finalVaultBalance);
        console.log(unicode"执行后 - 释放地址余额:", finalReleaseBalance);

        assertEq(finalVaultBalance, 0, unicode"保险库代币应该被清空");
        assertEq(
            finalReleaseBalance,
            initialReleaseBalance + initialVaultBalance,
            unicode"释放地址应该收到代币"
        );
    }

    /// @notice 测试 performUpkeep 在价格未达到时回滚
    function test_PerformUpkeep_RevertWhenPriceNotReached() public {
        // 设置低价，不满足条件
        MockPair(config.binanceLifeBnbPair).setReserves(1e18, 0.05e18);

        // 应该回滚，因为价格未达到
        vm.expectRevert("Price not reached target");
        vault.performUpkeep("");
    }

    /// @notice 测试 performUpkeep 在已允许提款时回滚
    function test_PerformUpkeep_RevertWhenAlreadyReleased() public {
        // 先通过紧急签名允许提款
        vm.prank(signerA);
        vault.emergencySign();
        vm.prank(signerB);
        vault.emergencySign();

        // 即使价格达到，也应该回滚（因为已经允许提款）
        MockPair(config.binanceLifeBnbPair).setReserves(1e18, 0.1e18);

        vm.expectRevert("Withdraw already allowed");
        vault.performUpkeep("");
    }

    /// @notice 测试自动化完整流程：checkUpkeep 返回 true 然后 performUpkeep 成功执行
    function test_Automation_FullFlow() public {
        // 设置初始状态
        MockPair(config.binanceLifeBnbPair).setReserves(1e18, 0.05e18); // 低价

        // 第一次检查：应该返回 false
        (bool upkeepNeeded1, ) = vault.checkUpkeep("");
        assertEq(upkeepNeeded1, false, unicode"低价时不应该需要upkeep");

        // 设置价格达到目标
        MockPair(config.binanceLifeBnbPair).setReserves(1e18, 0.1e18);

        // 第二次检查：应该返回 true
        (bool upkeepNeeded2, ) = vault.checkUpkeep("");
        assertEq(upkeepNeeded2, true, unicode"价格达到时应该需要upkeep");

        // 执行自动化
        uint256 initialBalance = MockToken(config.binanceLifeToken).balanceOf(
            releaseAddress
        );
        vault.performUpkeep("");

        // 验证结果
        uint256 finalBalance = MockToken(config.binanceLifeToken).balanceOf(
            releaseAddress
        );
        assertEq(
            finalBalance,
            initialBalance + 1000 ether,
            unicode"自动化执行后代币应该被转移"
        );
        assertEq(vault.released(), true, unicode"应该标记为已释放");

        // 第三次检查：应该返回 false（因为已经释放）
        (bool upkeepNeeded3, ) = vault.checkUpkeep("");
        assertEq(upkeepNeeded3, false, unicode"释放后不应该需要upkeep");
    }

    /// @notice 测试空保险库的自动化检查
    function test_CheckUpkeep_EmptyVault() public {
        // 创建新的空保险库
        MainVault emptyVault = new MainVault(helper);

        // 设置价格达到目标
        MockPair(config.binanceLifeBnbPair).setReserves(1e18, 0.1e18);

        (bool upkeepNeeded, ) = emptyVault.checkUpkeep("");

        // 即使价格达到，但保险库为空，checkUpkeep 应该返回 true
        // 但 performUpkeep 会失败（因为没有代币）
        assertEq(
            upkeepNeeded,
            true,
            unicode"价格达到时应该需要upkeep，即使保险库为空"
        );

        // 尝试执行会失败
        vm.expectRevert("No tokens in contract");
        emptyVault.performUpkeep("");
    }

    /// @notice 测试 performUpkeep 在空保险库时回滚
    function test_PerformUpkeep_RevertWhenNoTokens() public {
        // 创建新的空保险库
        MainVault emptyVault = new MainVault(helper);

        // 设置价格达到目标
        MockPair(config.binanceLifeBnbPair).setReserves(1e18, 0.1e18);

        // 应该回滚，因为没有代币
        vm.expectRevert("No tokens in contract");
        emptyVault.performUpkeep("");
    }
}
