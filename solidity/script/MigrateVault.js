// script/MigrateVault.js
const { ethers } = require('ethers');

async function queryPastMigrationEvents(oldVaultAddress, newVaultAddress, privateKey, rpcUrl) {
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const wallet = new ethers.Wallet(privateKey, provider);

    console.log("操作账户:", wallet.address);
    console.log("RPC URL:", rpcUrl);
    console.log("旧合约:", oldVaultAddress);
    console.log("新合约:", newVaultAddress);

    // 合约ABI
    const oldVaultABI = [
        "event UserDepositMigrated(address indexed user, uint256 amount, uint256 timestamp)"
    ];

    const newVaultABI = [
        "function importUserDepositsBatch(address[] users, uint256[] amounts, uint256[] timestamps, bool[] refundedStatus) external",
        "function totalDeposits() view returns (uint256)",
        "function getDepositorCount() view returns (uint256)"
    ];

    const oldVault = new ethers.Contract(oldVaultAddress, oldVaultABI, provider);
    const newVault = new ethers.Contract(newVaultAddress, newVaultABI, wallet);

    console.log("开始查询历史迁移事件...");

    try {
        // 查询历史迁移事件
        const events = await oldVault.queryFilter('UserDepositMigrated', 0, 'latest');
        console.log(`✅ 找到了 ${events.length} 个历史迁移事件`);

        if (events.length > 0) {
            // 处理并导入事件数据
            await processAndImportEvents(events, newVault);

            // 验证导入结果
            await verifyMigrationResult(newVault, events.length);
        } else {
            console.log("❌ 未找到历史迁移事件");
        }

    } catch (error) {
        console.error("查询事件时发生错误:", error);
    }
}

async function processAndImportEvents(events, newVault) {
    console.log("开始处理事件数据...");

    // 过滤有效事件
    const validEvents = events.filter(event => {
        const isValid = event.args &&
            event.args.user &&
            event.args.user !== ethers.ZeroAddress &&
            event.args.amount > 0;

        if (!isValid) {
            console.log(`⚠️ 过滤无效事件:`, {
                user: event.args?.user,
                amount: event.args?.amount
            });
        }

        return isValid;
    });

    console.log(`有效事件: ${validEvents.length}/${events.length}`);

    if (validEvents.length === 0) {
        console.log("❌ 没有有效事件可导入");
        return;
    }

    // 分批处理事件（避免Gas限制）
    const BATCH_SIZE = 25;
    let successfulImports = 0;

    for (let i = 0; i < validEvents.length; i += BATCH_SIZE) {
        const batch = validEvents.slice(i, i + BATCH_SIZE);
        const batchNumber = Math.floor(i / BATCH_SIZE) + 1;
        const totalBatches = Math.ceil(validEvents.length / BATCH_SIZE);

        console.log(`\n🔄 处理批次 ${batchNumber}/${totalBatches} (${batch.length} 个用户)`);

        try {
            const success = await importBatch(batch, newVault, batchNumber);
            if (success) {
                successfulImports += batch.length;
            }
        } catch (error) {
            console.error(`❌ 批次 ${batchNumber} 导入失败:`, error.message);
        }
    }

    console.log(`\n📊 导入统计: ${successfulImports}/${validEvents.length} 个用户导入成功`);
}

async function importBatch(batch, newVault, batchNumber) {
    // 准备批量导入数据
    const users = batch.map(event => event.args.user);
    const amounts = batch.map(event => event.args.amount);
    const timestamps = batch.map(event => event.args.timestamp);
    const refundedStatus = batch.map(() => false);

    // 验证数据完整性
    for (let i = 0; i < users.length; i++) {
        if (!users[i] || users[i] === ethers.ZeroAddress) {
            console.log(`❌ 批次 ${batchNumber} 中发现无效地址，跳过该批次`);
            return false;
        }
    }

    try {
        console.log(`📤 发送批次 ${batchNumber} 的导入交易...`);

        const tx = await newVault.importUserDepositsBatch(users, amounts, timestamps, refundedStatus);
        console.log(`⏳ 交易已发送: ${tx.hash}`);

        console.log(`⏳ 等待交易确认...`);
        const receipt = await tx.wait();

        console.log(`✅ 批次 ${batchNumber} 导入成功!`);
        console.log(`   Gas 消耗: ${receipt.gasUsed.toString()}`);
        console.log(`   区块: ${receipt.blockNumber}`);

        return true;

    } catch (error) {
        console.error(`❌ 批次 ${batchNumber} 导入失败:`, error.message);

        // 详细错误信息
        if (error.reason) {
            console.log(`   错误原因: ${error.reason}`);
        }
        if (error.code) {
            console.log(`   错误代码: ${error.code}`);
        }

        return false;
    }
}

async function verifyMigrationResult(newVault, expectedUserCount) {
    console.log("\n🔍 验证迁移结果...");

    try {
        const totalDeposits = await newVault.totalDeposits();
        const userCount = await newVault.getDepositorCount();

        console.log(`新合约状态:`);
        console.log(`   总存款: ${totalDeposits}`);
        console.log(`   用户数量: ${userCount}`);
        console.log(`   期望用户数量: ${expectedUserCount}`);

        if (userCount > 0) {
            console.log("✅ 迁移验证通过!");
        } else {
            console.log("⚠️  迁移可能未完全成功");
        }

    } catch (error) {
        console.error("验证迁移结果时出错:", error.message);
    }
}

// 主执行函数
async function main() {
    const oldVaultAddress = process.argv[2];
    const newVaultAddress = process.argv[3];
    const privateKey = process.argv[4];
    const rpcUrl = process.argv[5];

    // 参数验证
    if (!oldVaultAddress || !newVaultAddress || !privateKey || !rpcUrl) {
        console.error("❌ 错误: 必须提供所有参数");
        console.log("\n使用方法:");
        console.log("  node script/MigrateVault.js <旧合约地址> <新合约地址> <私钥> <RPC_URL>");
        console.log("\n示例:");
        console.log('  node script/MigrateVault.js 0x123... 0x456... 0xprivKey https://bsc-testnet.infura.io/v3/...');
        console.log("\n参数说明:");
        console.log("  旧合约地址: 已执行迁移的旧金库合约地址");
        console.log("  新合约地址: 要导入数据的新金库合约地址");
        console.log("  私钥: 用于发送导入交易的私钥（需要有新合约的owner权限）");
        console.log("  RPC_URL: BSC测试网的RPC端点");
        process.exit(1);
    }

    // 验证地址格式
    if (!ethers.isAddress(oldVaultAddress)) {
        console.error("❌ 无效的旧合约地址格式");
        process.exit(1);
    }

    if (!ethers.isAddress(newVaultAddress)) {
        console.error("❌ 无效的新合约地址格式");
        process.exit(1);
    }

    console.log("🚀 开始迁移数据重建流程...\n");

    try {
        await queryPastMigrationEvents(oldVaultAddress, newVaultAddress, privateKey, rpcUrl);
        console.log("\n🎉 迁移数据重建流程完成!");
    } catch (error) {
        console.error("\n💥 迁移流程执行失败:", error.message);
        process.exit(1);
    }
}

// 运行主函数
main();