// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BinanceLifePriceOracle} from "./BinanceLifePriceOracle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

/// @title 币安人生代币保险库合约（支持Chainlink Automation）
/// @notice 用户存入币安人生代币，当代币价格达到1U或双签授权时，可以释放所有代币到指定地址
contract MainVault {
    // 币安人生代币合约（常量地址确保安全）
    IERC20 public immutable TOKEN;

    // 价格预言机合约（自动部署新实例）
    BinanceLifePriceOracle public immutable ORACLE;

    // 代币释放的目标地址
    address public immutable RELEASE_ADDRESS;

    // 双签授权方地址
    address public immutable SIGNER_A;
    address public immutable SIGNER_B;
    // 目标价格：1U（与预言机价格单位一致，放大1e18倍）
    uint256 public immutable TARGET_PRICE;

    // 释放状态
    bool public released; // 价格触发释放
    bool public emergencySignedByA; // A方签名
    bool public emergencySignedByB; // B方签名

    /// @dev 构造函数，设置代币释放地址和双签授权方
    // 修改构造函数，直接接收参数
    constructor(
        address releaseAddress,
        address signerA,
        address signerB,
        address binanceLifeToken,
        address oracleAddress, // 接收已部署的 oracle 地址
        uint256 targetPrice
    ) {
        RELEASE_ADDRESS = releaseAddress;
        SIGNER_A = signerA;
        SIGNER_B = signerB;
        TOKEN = IERC20(binanceLifeToken);
        ORACLE = BinanceLifePriceOracle(oracleAddress); // 使用已部署的实例
        TARGET_PRICE = targetPrice;
    }

    /// @notice 检查是否允许提款
    /// @dev 价格触发释放 或 双签授权 都允许提款
    function withdrawAllowed() public view returns (bool) {
        return released || (emergencySignedByA && emergencySignedByB);
    }

    /// @notice 存入币安人生代币
    /// @dev 只能存入币安人生代币，且未允许提款时才能存入
    /// @param amount 存入的代币数量
    function deposit(uint256 amount) external {
        require(
            !withdrawAllowed(),
            "Withdraw already allowed, cannot deposit more"
        );
        require(amount > 0, "Deposit amount must be greater than 0");

        bool success = TOKEN.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");
    }

    /// @notice 检查价格并释放代币
    /// @dev 当币安人生价格达到目标价格时，将所有代币释放到指定地址
    /// @dev 这个函数将被 Chainlink Automation 调用
    function checkAndRelease() external {
        require(msg.sender == address(this), "only self call");

        require(!withdrawAllowed(), "Withdraw already allowed");

        uint256 currentPrice = ORACLE.getPrice();
        require(currentPrice >= TARGET_PRICE, "Price not reached target");

        released = true;

        uint256 balance = TOKEN.balanceOf(address(this));
        require(balance > 0, "No tokens in contract");

        bool success = TOKEN.transfer(RELEASE_ADDRESS, balance);
        require(success, "Token release failed");
    }

    /// @notice 紧急签名授权
    /// @dev 只有指定的签名者可以调用此函数
    function emergencySign() external {
        require(!withdrawAllowed(), "Withdraw already allowed");
        require(
            msg.sender == SIGNER_A || msg.sender == SIGNER_B,
            "Only signers can call this function"
        );

        if (msg.sender == SIGNER_A) {
            emergencySignedByA = true;
        } else {
            emergencySignedByB = true;
        }

        // 如果双方都已签名，执行释放
        if (emergencySignedByA && emergencySignedByB) {
            released = true;

            uint256 balance = TOKEN.balanceOf(address(this));
            require(balance > 0, "No tokens in contract");

            bool success = TOKEN.transfer(RELEASE_ADDRESS, balance);
            require(success, "Token release failed");
        }
    }

    /// @notice 获取当前价格
    /// @dev 用于前端显示当前币安人生代币价格
    /// @return 当前价格（放大1e18倍）
    function getCurrentPrice() external view returns (uint256) {
        return ORACLE.getPrice();
    }

    /// @notice 获取合约中的代币余额
    /// @dev 用于查询当前合约持有的币安人生代币数量
    /// @return 代币余额
    function getContractBalance() external view returns (uint256) {
        return TOKEN.balanceOf(address(this));
    }

    /// @notice 检查是否满足自动化执行条件
    /// @dev Chainlink Automation 会调用此函数检查条件
    /// @return upkeepNeeded 是否需要执行
    /// @return performData 执行数据
    function checkUpkeep(
        bytes calldata
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        // 检查是否已经释放
        if (withdrawAllowed()) {
            return (false, "");
        }

        // 检查价格是否达到目标
        uint256 currentPrice = ORACLE.getPrice();
        upkeepNeeded = (currentPrice >= TARGET_PRICE);

        return (upkeepNeeded, "");
    }

    /// @notice 执行自动化任务
    /// @dev Chainlink Automation 会调用此函数执行释放
    function performUpkeep(bytes calldata) external {
        // 直接调用现有的释放逻辑
        this.checkAndRelease();
    }
}
