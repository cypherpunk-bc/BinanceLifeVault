// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MockPair} from "../test/mocks/MockPair.sol";

/// @title HelperConfig - 根据不同网络提供配置参数
/// @notice 在部署时自动选择主网、测试网或本地配置
contract HelperConfig {
    struct NetworkConfig {
        address releaseAddress;
        address signerA;
        address signerB;
        address binanceLifeToken;
        address wbnb;
        address usdt;
        address bnbUsdtPair;
        address binanceLifeBnbPair;
        uint256 targetPrice; // 目标价格，放大1e18倍
    }

    NetworkConfig public config;

    constructor(uint256 targetPrice) {
        uint256 chainId = block.chainid;
        if (chainId == 56) {
            //  BNB Chain Mainnet
            config = getMainnetConfig(targetPrice);
        } else if (chainId == 97) {
            //  BNB Chain Testnet
            config = getTestnetConfig(targetPrice);
        } else {
            //  Local Anvil or Hardhat
            config = getLocalConfig(targetPrice);
        }
    }

    // ---------------------- MAINNET CONFIG ----------------------
    function getMainnetConfig(
        uint256 targetPrice
    ) public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                releaseAddress: 0x1556a9A5C01ecc4eF11e751CacC847DD36971be7,
                signerA: 0x1556a9A5C01ecc4eF11e751CacC847DD36971be7,
                signerB: 0xb9C5A10Abd15e5583Da8Ab67EBA3D51092db28F2,
                binanceLifeToken: 0x924fa68a0FC644485b8df8AbfA0A41C2e7744444,
                wbnb: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,
                usdt: 0x55d398326f99059fF775485246999027B3197955,
                bnbUsdtPair: 0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE,
                binanceLifeBnbPair: 0x66f289De31EEF70d52186729d2637Ac978CFC56B,
                targetPrice: targetPrice
            });
    }

    // ---------------------- TESTNET CONFIG ----------------------
    function getTestnetConfig(
        uint256 targetPrice
    ) public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                releaseAddress: 0x1556a9A5C01ecc4eF11e751CacC847DD36971be7,
                signerA: 0x1556a9A5C01ecc4eF11e751CacC847DD36971be7,
                signerB: 0xb9C5A10Abd15e5583Da8Ab67EBA3D51092db28F2,
                // 测试网替换为部署的 Mock 地址
                binanceLifeToken: 0x9CF6392765683E147b1B5BdB60654F9d627773cc,
                wbnb: 0x05f0fEE5b8460a773872f8e4e9D23aE109BB3592,
                usdt: 0x21210a6213D7B1c6D83f393488F0aFC0913EBEd5,
                bnbUsdtPair: 0x5d6Bf42E303e3189664aFaa2EA5e87E9a719dB38,
                binanceLifeBnbPair: 0xd6f268AF3C4C4Dd7852f51aedd9De12e7048Ec73,
                targetPrice: targetPrice
            });
    }

    // ---------------------- LOCAL CONFIG ----------------------
    /// @notice 本地测试时使用 MockPair 模拟价格
    function getLocalConfig(
        uint256 targetPrice
    ) internal returns (NetworkConfig memory) {
        // 模拟两个 pair
        MockPair bnbUsdt = new MockPair(
            address(0x111),
            address(0x222),
            1e18,
            300e18
        ); // BNB=300 USDT
        MockPair lifeBnb = new MockPair(
            address(0x333),
            address(0x111),
            1e18,
            0.1e18
        ); // 1 LIFE=0.1 BNB

        return
            NetworkConfig({
                releaseAddress: address(0xAAA),
                signerA: 0x1111111111111111111111111111111111111111,
                signerB: 0x2222222222222222222222222222222222222222,
                binanceLifeToken: address(0x333),
                wbnb: address(0x111),
                usdt: address(0x222),
                bnbUsdtPair: address(bnbUsdt),
                binanceLifeBnbPair: address(lifeBnb),
                targetPrice: targetPrice
            });
    }

    function activeConfig() public view returns (NetworkConfig memory) {
        return config;
    }
}
