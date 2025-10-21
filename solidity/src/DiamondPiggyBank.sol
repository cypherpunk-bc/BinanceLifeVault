// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BinanceLifePriceOracle} from "./BinanceLifePriceOracle.sol";

/// @title 多用户币安人生代币保险库合约（支持完整资产和记录迁移）
/// @notice 多个用户存入币安人生代币，当代币价格达到目标价格时，自动启用退款功能
contract DiamondPiggyBank is Ownable {
    // 币安人生代币合约（不可变）
    IERC20 public immutable TOKEN;

    // 价格预言机合约（不可变）
    BinanceLifePriceOracle public immutable ORACLE;

    // 目标价格：1U（放大1e18倍，不可变）
    uint256 public immutable TARGET_PRICE;

    // 双签授权方地址（可更新）
    address public signerA;
    address public signerB;

    // 释放状态
    bool public refundEnabled; // 价格触发退款开关
    bool public emergencySignedByA; // A方签名状态
    bool public emergencySignedByB; // B方签名状态

    // 迁移状态
    bool public migrationEnabled; // 迁移开关
    address public newVaultAddress; // 新金库地址

    // 用户存款记录结构体
    struct UserDeposit {
        uint256 amount; // 存款金额
        uint256 timestamp; // 存款时间
        bool refunded; // 是否已退款
        bool migrated; // 是否已迁移到新金库
    }

    // 用户地址 => 存款记录
    mapping(address => UserDeposit) public deposits;

    // 所有存款用户地址列表（用于前端展示）
    address[] public depositors;

    // 总存款金额
    uint256 public totalDeposits;

    // 事件定义
    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event Refunded(address indexed user, uint256 amount, uint256 timestamp);
    event RefundEnabled(uint256 currentPrice, uint256 targetPrice);
    event EmergencySigned(address indexed signer);
    event SignerAUpdated(
        address indexed oldSignerA,
        address indexed newSignerA,
        address indexed updatedBy
    );
    event SignerBUpdated(
        address indexed oldSignerB,
        address indexed newSignerB,
        address indexed updatedBy
    );
    event BothSignersUpdated(
        address indexed newSignerA,
        address indexed newSignerB,
        address indexed updatedBy
    );
    event MigrationPrepared(
        address indexed newVaultAddress,
        address indexed preparedBy
    );
    event MigrationExecuted(
        address indexed newVaultAddress,
        uint256 migratedAmount,
        uint256 userCount,
        uint256 timestamp
    );
    event UserDepositMigrated(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    /// @dev 构造函数
    constructor(
        address initialOwner,
        address _signerA,
        address _signerB,
        address binanceLifeToken,
        address oracleAddress,
        uint256 targetPrice
    ) Ownable(initialOwner) {
        require(
            _signerA != address(0) && _signerB != address(0),
            "Invalid signer address"
        );
        require(_signerA != _signerB, "Signers must be different");
        require(binanceLifeToken != address(0), "Invalid token address");
        require(oracleAddress != address(0), "Invalid oracle address");
        require(targetPrice > 0, "Invalid target price");

        signerA = _signerA;
        signerB = _signerB;
        TOKEN = IERC20(binanceLifeToken);
        ORACLE = BinanceLifePriceOracle(oracleAddress);
        TARGET_PRICE = targetPrice;
    }

    /// @notice 检查是否允许提款
    function withdrawAllowed() public view returns (bool) {
        return refundEnabled || (emergencySignedByA && emergencySignedByB);
    }

    /// @notice 检查是否允许迁移
    function migrationAllowed() public view returns (bool) {
        return migrationEnabled && newVaultAddress != address(0);
    }

    /// @notice 用户存入币安人生代币
    function deposit(uint256 amount) external {
        require(
            !withdrawAllowed(),
            "Vault: Withdraw already allowed, cannot deposit more"
        );
        require(
            !migrationAllowed(),
            "Vault: Migration enabled, cannot deposit"
        );
        require(amount > 0, "Vault: Deposit amount must be greater than 0");

        UserDeposit storage userDeposit = deposits[msg.sender];

        if (userDeposit.amount == 0) {
            depositors.push(msg.sender);
        }

        userDeposit.amount += amount;
        userDeposit.timestamp = block.timestamp;
        totalDeposits += amount;

        bool success = TOKEN.transferFrom(msg.sender, address(this), amount);
        require(success, "Vault: Token transfer failed");

        emit Deposited(msg.sender, amount, block.timestamp);
    }

    /// @notice 用户提取退款
    function withdrawRefund() external {
        require(withdrawAllowed(), "Vault: Withdraw not allowed yet");
        require(!migrationAllowed(), "Vault: Migration enabled, use new vault");

        UserDeposit storage userDeposit = deposits[msg.sender];
        require(userDeposit.amount > 0, "Vault: No deposit to refund");
        require(!userDeposit.refunded, "Vault: Already refunded");

        uint256 refundAmount = userDeposit.amount;
        userDeposit.refunded = true;
        userDeposit.amount = 0;
        totalDeposits -= refundAmount;

        bool success = TOKEN.transfer(msg.sender, refundAmount);
        require(success, "Vault: Token transfer failed");

        emit Refunded(msg.sender, refundAmount, block.timestamp);
    }

    /// @notice 紧急签名授权（同时处理退款和迁移授权）
    function emergencySign() external {
        require(!withdrawAllowed(), "Vault: Withdraw already allowed");
        require(
            msg.sender == signerA || msg.sender == signerB,
            "Vault: Only signers can call this function"
        );

        if (msg.sender == signerA) {
            emergencySignedByA = true;
        } else {
            emergencySignedByB = true;
        }

        emit EmergencySigned(msg.sender);

        // 如果双方都已签名，启用退款功能
        if (emergencySignedByA && emergencySignedByB) {
            refundEnabled = true;

            // 如果已经设置了新金库地址，同时启用迁移
            if (newVaultAddress != address(0) && !migrationEnabled) {
                migrationEnabled = true;
                emit MigrationPrepared(newVaultAddress, msg.sender);
            }
        }
    }

    /// @notice 设置新金库地址（仅合约所有者）
    function setNewVaultAddress(address _newVaultAddress) external onlyOwner {
        require(_newVaultAddress != address(0), "Vault: Invalid vault address");
        require(
            _newVaultAddress != address(this),
            "Vault: Cannot set self as new vault"
        );

        newVaultAddress = _newVaultAddress;

        // 如果已经双签授权，直接启用迁移
        if (emergencySignedByA && emergencySignedByB && !migrationEnabled) {
            migrationEnabled = true;
            emit MigrationPrepared(_newVaultAddress, msg.sender);
        }
    }

    /// @notice 执行完整迁移（仅合约所有者）
    /// @dev 迁移资产和所有用户存款记录到新金库
    function executeMigration() external onlyOwner {
        require(migrationAllowed(), "Vault: Migration not allowed");
        require(totalDeposits > 0, "Vault: No deposits to migrate");

        uint256 contractBalance = TOKEN.balanceOf(address(this));
        require(contractBalance > 0, "Vault: No tokens to migrate");

        // 转移代币到新金库
        bool success = TOKEN.transfer(newVaultAddress, contractBalance);
        require(success, "Vault: Token migration failed");

        // 迁移用户存款记录（通过事件记录，新金库可以监听并重建记录）
        uint256 migratedUserCount = 0;
        for (uint256 i = 0; i < depositors.length; i++) {
            address user = depositors[i];
            UserDeposit storage userDeposit = deposits[user];

            // 只迁移未退款且还有余额的用户
            if (userDeposit.amount > 0 && !userDeposit.refunded) {
                userDeposit.migrated = true;
                migratedUserCount++;

                // 发出迁移事件，新金库可以监听这些事件来重建用户记录
                emit UserDepositMigrated(
                    user,
                    userDeposit.amount,
                    userDeposit.timestamp
                );
            }
        }

        // 更新总存款（理论上应该为0，因为所有资金已转移）
        totalDeposits = 0;

        emit MigrationExecuted(
            newVaultAddress,
            contractBalance,
            migratedUserCount,
            block.timestamp
        );
    }

    /// @notice Chainlink Automation: 检查执行条件
    function checkUpkeep(
        bytes calldata
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        if (withdrawAllowed() || totalDeposits == 0 || migrationAllowed()) {
            return (false, "");
        }

        uint256 currentPrice = ORACLE.getPrice();
        upkeepNeeded = (currentPrice >= TARGET_PRICE);

        return (upkeepNeeded, "");
    }

    /// @notice Chainlink Automation: 执行自动化任务
    function performUpkeep(bytes calldata) external {
        require(!withdrawAllowed(), "Vault: Withdraw already allowed");
        require(totalDeposits > 0, "Vault: No deposits to refund");
        require(!migrationAllowed(), "Vault: Migration enabled");

        uint256 currentPrice = ORACLE.getPrice();
        require(
            currentPrice >= TARGET_PRICE,
            "Vault: Price not reached target"
        );

        refundEnabled = true;
        emit RefundEnabled(currentPrice, TARGET_PRICE);
    }

    // ==================== 更新签名地址函数 ====================
    function updateSignerA(address newSignerA) external onlyOwner {
        require(newSignerA != address(0), "Vault: Invalid signer address");
        require(
            newSignerA != signerB,
            "Vault: SignerA must be different from SignerB"
        );

        address oldSignerA = signerA;
        signerA = newSignerA;

        if (msg.sender == oldSignerA || emergencySignedByA) {
            emergencySignedByA = false;
        }

        emit SignerAUpdated(oldSignerA, newSignerA, msg.sender);
    }

    function updateSignerB(address newSignerB) external onlyOwner {
        require(newSignerB != address(0), "Vault: Invalid signer address");
        require(
            newSignerB != signerA,
            "Vault: SignerB must be different from SignerA"
        );

        address oldSignerB = signerB;
        signerB = newSignerB;

        if (msg.sender == oldSignerB || emergencySignedByB) {
            emergencySignedByB = false;
        }

        emit SignerBUpdated(oldSignerB, newSignerB, msg.sender);
    }

    function updateBothSigners(
        address newSignerA,
        address newSignerB
    ) external onlyOwner {
        require(
            newSignerA != address(0) && newSignerB != address(0),
            "Vault: Invalid signer address"
        );
        require(newSignerA != newSignerB, "Vault: Signers must be different");

        address oldSignerA = signerA;
        address oldSignerB = signerB;

        signerA = newSignerA;
        signerB = newSignerB;

        emergencySignedByA = false;
        emergencySignedByB = false;

        emit BothSignersUpdated(newSignerA, newSignerB, msg.sender);
        emit SignerAUpdated(oldSignerA, newSignerA, msg.sender);
        emit SignerBUpdated(oldSignerB, newSignerB, msg.sender);
    }

    // ==================== 视图函数 ====================
    function getUserDeposit(
        address user
    )
        external
        view
        returns (
            uint256 amount,
            uint256 timestamp,
            bool refunded,
            bool migrated
        )
    {
        UserDeposit memory userDeposit = deposits[user];
        return (
            userDeposit.amount,
            userDeposit.timestamp,
            userDeposit.refunded,
            userDeposit.migrated
        );
    }

    function getDepositorCount() external view returns (uint256) {
        return depositors.length;
    }

    function getCurrentPrice() external view returns (uint256) {
        return ORACLE.getPrice();
    }

    function getContractBalance() external view returns (uint256) {
        return TOKEN.balanceOf(address(this));
    }

    function getSigners() external view returns (address, address) {
        return (signerA, signerB);
    }

    function getMigrationStatus() external view returns (bool, address) {
        return (migrationEnabled, newVaultAddress);
    }

    /// @notice 获取待迁移的用户数量
    function getPendingMigrationCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < depositors.length; i++) {
            UserDeposit memory userDeposit = deposits[depositors[i]];
            if (
                userDeposit.amount > 0 &&
                !userDeposit.refunded &&
                !userDeposit.migrated
            ) {
                count++;
            }
        }
        return count;
    }
}
