BinanceLife Token Vault - 部署与浏览器操作指南
📋 项目概述

BinanceLife Token Vault 是自用锁仓合约，用于存储币安人生代币（BinanceLife Token），提供两种释放方式：

价格触发释放：币安人生代币价格 ≥ 1 USDT，由 Chainlink Automation 自动释放

双签紧急释放：两个授权签名者同时操作，立即释放全部代币

⚠️ 只针对自用，不考虑其他人代币误打入或闪电贷攻击。

🏗️ 环境准备

安装 Node.js（推荐 18+）

安装 Foundry：官方安装指南

curl -L https://foundry.paradigm.xyz | bash
foundryup


准备 BSC RPC URL 和钱包 私钥

1️⃣ 获取代码
git clone https://github.com/<your-repo>/BinanceLifeVault.git
cd BinanceLifeVault

2️⃣ 安装依赖并编译
forge install
forge build

3️⃣ 部署合约（命令行）
forge create src/MainVault.sol:MainVault \
  --constructor-args <releaseAddress> <signerA> <signerB> \
  --rpc-url <BSC_RPC_URL> \
  --private-key <PRIVATE_KEY>


替换 <releaseAddress> / <signerA> / <signerB> 为你的地址

<BSC_RPC_URL> 为 BSC 节点地址

<PRIVATE_KEY> 为钱包私钥

⚠️ 部署完成后，请记录合约地址，用于浏览器操作和 Chainlink Automation 设置
⚠️ 部署后合约逻辑锁定，无法修改。

4️⃣ 存入代币（浏览器操作）
步骤 1：授权 Vault 合约（approve）

打开 币安人生代币合约页面（BscScan）

点击 Write Contract → Connect to Web3，连接钱包

找到 approve 方法并填写参数：

参数	说明
spender	Vault 合约地址（你部署的 MainVault 地址）
amount	想存入的代币数量（如 1000 个代币，输入 1000000000000000000000，注意代币 18 位小数）

点击 Write 并在钱包中确认交易

⚠️ 注意：存币前必须先执行 approve()，否则 deposit() 会失败。

步骤 2：存币到 Vault

打开 MainVault 合约页面（BscScan）

点击 Write Contract → deposit

输入存入数量

提交交易并确认

5️⃣ 配置 Chainlink Automation

打开 Chainlink Automation

创建 Upkeep：

Name：BinanceLifeVaultRelease

Contract Address：Vault 合约地址

Gas Limit：300,000

Check Data / Perform Data：空

提交并确认

给 Upkeep 充值 LINK（0.1–1 LINK 测试即可）

Chainlink Automation 会定期调用 performUpkeep()，自动触发价格释放。

6️⃣ 双签紧急释放（浏览器操作）

打开 MainVault → Write Contract → emergencySign

分别由 signerA 和 signerB 调用

当两个签名完成后，合约立即释放所有代币到 releaseAddress

7️⃣ 查询合约状态（浏览器操作）

在 Read Contract 页面调用：

方法	             说明
getCurrentPrice	    当前币安人生价格（USDT）
getContractBalance	合约代币余额
withdrawAllowed	    是否已释放代币

✅ 无需支付 Gas，可直接查看。

⚠️ 注意事项

存入代币前必须先执行 approve()

价格触发释放只能通过 Chainlink Automation

双签释放必须由预设 signerA 和 signerB 调用

释放完成后无法再次存款

所有交易（deposit / emergencySign）需要 BNB 支付 Gas

Chainlink Automation 消耗 LINK

⚠️ 重要安全说明

合约只能处理币安人生代币！如果误将其他代币转入合约地址，这些代币将永久丢失，无法恢复！