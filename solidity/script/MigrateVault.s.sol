// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {DiamondPiggyBank} from "../src/DiamondPiggyBank.sol";

contract MigrateVault is Script {
    function run() external {
        // 旧金库地址（部署好的旧 Vault）
        DiamondPiggyBank vault = DiamondPiggyBank(
            0x0B5e5422fF23DD02b1b4eD0c11fc8A1C003982AC
        );

        address owner = vault.owner();
        address signerA = vault.signerA();
        address signerB = vault.signerB();

        // 新金库地址，随便填一个测试地址
        address newVault = address(0x1111111111111111111111111111111111110111);

        // 读取旧金库信息
        uint256 totalDeposits = vault.getContractBalance();
        uint256 pendingUsers = vault.getPendingMigrationCount();

        console.log("=== Old Vault Info ===");
        console.log("Contract balance:", totalDeposits);
        console.log("Pending users:", pendingUsers);

        // fork 模拟执行，不广播
        vm.startPrank(owner);
        vault.setNewVaultAddress(newVault);
        vm.stopPrank();

        vm.startPrank(signerA);
        vault.emergencySign();
        vm.stopPrank();

        vm.startPrank(signerB);
        vault.emergencySign();
        vm.stopPrank();

        vm.startPrank(owner);
        vault.executeMigration();
        vm.stopPrank();

        // 读取迁移后的信息
        uint256 balanceAfter = vault.getContractBalance();
        uint256 pendingAfter = vault.getPendingMigrationCount();

        console.log("=== After Migration ===");
        console.log("Contract balance:", balanceAfter);
        console.log("Pending users:", pendingAfter);

        console.log("=== Migration simulation done ===");
    }
}
