// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DiamondPiggyBank} from "../src/DiamondPiggyBank.sol";
import {BinanceLifePriceOracle} from "../src/BinanceLifePriceOracle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

/// @title 部署脚本：MainVault + BinanceLifePriceOracle
/// @notice 根据当前网络环境自动选择配置进行部署
contract Deploy is Script {
    function deployer(uint256 targetPrice) public returns (address, address) {
        // 1. 在本地内存中创建 HelperConfig 并获取配置
        HelperConfig helper = new HelperConfig(targetPrice);
        HelperConfig.NetworkConfig memory config = helper.activeConfig();

        console.log("Deploying to network:", block.chainid);
        console.log("Token Address:", config.binanceLifeToken);

        // 2. 开启广播
        vm.startBroadcast();

        // 3. 部署 BinanceLifePriceOracle，直接传递配置值
        BinanceLifePriceOracle oracle = new BinanceLifePriceOracle(
            config.binanceLifeToken,
            config.wbnb,
            config.usdt,
            config.bnbUsdtPair,
            config.binanceLifeBnbPair
        );
        console.log("Deployed Oracle at:", address(oracle));

        // 4. 部署 MainVault，直接传递配置值
        DiamondPiggyBank vault = new DiamondPiggyBank(
            config.releaseAddress,
            config.signerA,
            config.signerB,
            config.binanceLifeToken,
            address(oracle), // 传递已部署的 oracle 地址
            config.targetPrice
        );
        console.log("Deployed Vault at:", address(vault));

        vm.stopBroadcast();

        console.log("Deployment complete!");
        return (address(vault), address(oracle));
    }

    function run(uint targetPrice) external {
        deployer(targetPrice);
    }
}
