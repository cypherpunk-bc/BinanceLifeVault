if (typeof window.ethereum === 'undefined' && typeof window.okxwallet !== 'undefined') {
    window.ethereum = window.okxwallet;
}

import { createWalletClient, custom } from 'https://esm.sh/viem'
import { createPublicClient, http, parseEther, formatEther } from 'https://esm.sh/viem'
import { bsc } from 'https://esm.sh/viem/chains'
import { CONTRACT_ABI } from './contractAbi.js'

// 配置 - 部署时修改这里
const CONTRACT_ADDRESS = "0xd6f268AF3C4C4Dd7852f51aedd9De12e7048Ec73";
const RPC_URL = "https://bsc-dataseed.binance.org/";

// 全局变量
let walletClient, publicClient, account, contract


// DOM 元素
const connectButton = document.getElementById('connectButton')
const walletInfo = document.getElementById('walletInfo')
const walletAddress = document.getElementById('walletAddress')
const approveButton = document.getElementById('approveButton')
const depositButton = document.getElementById('depositButton')
const depositAmountInput = document.getElementById('depositAmount')
const withdrawButton = document.getElementById('withdrawButton')
const withdrawInfo = document.getElementById('withdrawInfo')
const userDepositElement = document.getElementById('userDeposit')
const totalSupplyElement = document.getElementById('totalSupply')
const totalAmountElement = document.getElementById('totalAmount')
const totalDepositorsElement = document.getElementById('totalDepositors')
const targetAmountElement = document.getElementById('targetAmount')

// 初始化
async function init() {
    console.log('初始化开始...');

    // 无论有没有钱包，先初始化公共客户端
    setupPublicClient();

    // 立即读取一次公共数据（总额、目标等）
    await updateContractData();

    // 开启定时刷新
    setInterval(updateContractData, 30000);

    if (typeof window.ethereum !== 'undefined') {
        console.log('检测到钱包环境');
        await checkConnectionStatus();
    } else {
        console.log('未检测到钱包插件');
        if (connectButton) connectButton.textContent = "查看模式";
    }
}

// 公共客户端设置
function setupPublicClient() {
    publicClient = createPublicClient({
        chain: bsc,
        transport: http(RPC_URL)
    });
    contract = {
        address: CONTRACT_ADDRESS,
        abi: CONTRACT_ABI
    };
}

// 检查连接状态
async function checkConnectionStatus() {
    try {
        console.log('检查连接状态...');
        const accounts = await window.ethereum.request({ method: 'eth_accounts' });
        console.log('当前账户:', accounts);

        if (accounts.length > 0) {
            account = accounts[0];
            console.log('已连接账户:', account);
            await setupClients();
            updateUIAfterConnection();
            await updateContractData();
        }
    } catch (error) {
        console.error('检查连接状态失败:', error);
    }
}

// 设置钱包客户端
async function setupClients() {
    console.log('设置钱包客户端...');

    walletClient = createWalletClient({
        chain: bsc,
        transport: custom(window.ethereum)
    });

    console.log('钱包客户端设置完成');
}

// 连接钱包
async function connect() {
    console.log('连接钱包按钮点击');

    if (typeof window.ethereum !== 'undefined') {
        try {
            console.log('请求账户访问...');
            const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
            account = accounts[0];
            console.log('连接成功，账户:', account);

            await setupClients();
            updateUIAfterConnection();
            await updateContractData();

        } catch (error) {
            console.error('连接钱包失败:', error);
            alert('连接失败: ' + error.message);
        }
    } else {
        connectButton.textContent = "请安装钱包!";
    }
}

// 更新UI
function updateUIAfterConnection() {
    console.log('更新UI,账户:', account);

    if (walletAddress) {
        walletAddress.textContent = `${account.substring(0, 6)}...${account.substring(account.length - 4)}`;
    }

    if (walletInfo) {
        walletInfo.style.display = 'block';
    }

    if (connectButton) {
        connectButton.textContent = '已连接';
        connectButton.disabled = true;
        connectButton.style.backgroundColor = '#0a0';
    }
}

// 更新合约数据
async function updateContractData() {
    if (!publicClient) return;

    try {
        // 1. 读取数据
        const [totalDeposits, depositorCount, targetPrice, currentPrice, withdrawAllowed] = await Promise.all([
            publicClient.readContract({ ...contract, functionName: 'totalDeposits' }),
            publicClient.readContract({ ...contract, functionName: 'getDepositorCount' }),
            publicClient.readContract({ ...contract, functionName: 'TARGET_PRICE' }),
            publicClient.readContract({ ...contract, functionName: 'getCurrentPrice' }),
            publicClient.readContract({ ...contract, functionName: 'withdrawAllowed' })
        ]);

        // 2. 更新公共 UI 
        if (totalSupplyElement) totalSupplyElement.textContent = parseFloat(formatEther(totalDeposits)).toLocaleString();
        if (totalAmountElement) totalAmountElement.textContent = `$${(parseFloat(formatEther(totalDeposits)) * parseFloat(formatEther(currentPrice))).toLocaleString()}`;
        if (totalDepositorsElement) totalDepositorsElement.textContent = depositorCount.toString();
        if (targetAmountElement) targetAmountElement.textContent = `$${parseFloat(formatEther(targetPrice)).toLocaleString()}`;

        // 3. 处理提款信息 
        if (withdrawInfo) {
            withdrawInfo.textContent = withdrawAllowed ? '提款功能已开启' : '提款功能尚未开启';
            withdrawInfo.style.color = withdrawAllowed ? '#0a0' : '#f00';
        }

        // 4. 更新用户个人存款 
        if (account && userDepositElement) {
            const userDeposit = await publicClient.readContract({
                ...contract,
                functionName: 'getUserDeposit',
                args: [account]
            });

            const userDepositAmount = parseFloat(formatEther(userDeposit[0]));
            userDepositElement.textContent = `${userDepositAmount.toLocaleString()} BN`;

            if (userDeposit[2]) userDepositElement.innerHTML += ' <span style="color:red">(已退款)</span>';
            else if (userDeposit[3]) userDepositElement.innerHTML += ' <span style="color:orange">(已迁移)</span>';

            if (withdrawButton) {
                withdrawButton.disabled = false;
                withdrawButton.style.opacity = '1';
            }
        } else if (userDepositElement) {
            userDepositElement.textContent = '未连接钱包';
        }

    } catch (error) {
        console.error('更新合约数据失败:', error);
    }
}

// 批准代币
async function approveTokens() {
    try {
        const amount = depositAmountInput.value;
        if (!amount || amount <= 0) {
            alert('请输入有效的代币数量');
            return;
        }

        const tokenAddress = await publicClient.readContract({ ...contract, functionName: 'TOKEN' });
        const amountWei = parseEther(amount);

        const hash = await walletClient.writeContract({
            address: tokenAddress,
            abi: [{
                name: 'approve',
                type: 'function',
                inputs: [
                    { name: 'spender', type: 'address' },
                    { name: 'amount', type: 'uint256' }
                ],
                outputs: [{ name: '', type: 'bool' }],
                stateMutability: 'nonpayable'
            }],
            functionName: 'approve',
            args: [CONTRACT_ADDRESS, amountWei],
            account
        });

        approveButton.textContent = '交易处理中...';
        await publicClient.waitForTransactionReceipt({ hash });
        approveButton.textContent = '已批准';
        alert(`成功批准 ${amount} BN 代币`);

    } catch (error) {
        console.error('批准代币失败:', error);
        alert('批准代币失败: ' + error.message);
        approveButton.textContent = '批准代币';
    }
}

// 存款
async function depositTokens() {
    try {
        const amount = depositAmountInput.value;
        if (!amount || amount <= 0) {
            alert('请输入有效的代币数量');
            return;
        }

        const amountWei = parseEther(amount);
        const hash = await walletClient.writeContract({
            ...contract,
            functionName: 'deposit',
            args: [amountWei],
            account
        });

        depositButton.textContent = '交易处理中...';
        await publicClient.waitForTransactionReceipt({ hash });
        depositButton.textContent = '存入代币';

        depositAmountInput.value = '';
        approveButton.textContent = '批准代币';
        await updateContractData();

        alert(`成功存入 ${amount} BN 代币`);

    } catch (error) {
        console.error('存款失败:', error);
        alert('存款失败: ' + error.message);
        depositButton.textContent = '存入代币';
    }
}

// 提款
async function withdrawTokens() {
    try {
        // 检查提款是否开启
        const withdrawAllowed = await publicClient.readContract({
            ...contract,
            functionName: 'withdrawAllowed'
        });

        if (!withdrawAllowed) {
            alert('提款功能尚未开启，无法提款');
            return;
        }

        // 检查用户是否有存款
        const userDeposit = await publicClient.readContract({
            ...contract,
            functionName: 'getUserDeposit',
            args: [account]
        });

        const userDepositAmount = parseFloat(formatEther(userDeposit[0]));
        if (userDepositAmount <= 0) {
            alert('您没有存款可提取');
            return;
        }

        const hash = await walletClient.writeContract({
            ...contract,
            functionName: 'withdrawRefund',
            account
        });

        withdrawButton.textContent = '提款处理中...';
        await publicClient.waitForTransactionReceipt({ hash });
        withdrawButton.textContent = '提款';

        await updateContractData();
        alert('成功提款!');

    } catch (error) {
        console.error('提款失败:', error);
        alert('提款失败: ' + error.message);
        withdrawButton.textContent = '提款';
    }
}

// 事件监听
connectButton.onclick = connect;
approveButton.onclick = approveTokens;
depositButton.onclick = depositTokens;
withdrawButton.onclick = withdrawTokens;

//页面加载时初始化
window.addEventListener('load', () => {
    setTimeout(() => {
        init(); // 延迟初始化
    }, 1000);
});


// 监听账户变化
if (typeof window.ethereum !== 'undefined') {
    window.ethereum.on('accountsChanged', (accounts) => {
        console.log('账户变化:', accounts);

        if (accounts.length === 0) {
            location.reload();
        } else {
            account = accounts[0];
            updateUIAfterConnection();
            updateContractData();
        }
    });
}