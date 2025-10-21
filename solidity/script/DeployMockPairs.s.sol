// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MockPair} from "../test/mocks/MockPair.sol";

contract DeployMockPairs is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 直接硬编码代币地址
        address lifeToken = 0x9CF6392765683E147b1B5BdB60654F9d627773cc; // MockBinanceLIFE 地址
        address wbnbToken = 0x05f0fEE5b8460a773872f8e4e9D23aE109BB3592; // MockWBNB 地址
        address usdtToken = 0x21210a6213D7B1c6D83f393488F0aFC0913EBEd5; // MockUSDT 地址

        // 部署 MockPair 合约，初始储备量为 1 LIFE 和 0.5 WBNB
        MockPair pair = new MockPair(
            lifeToken,
            wbnbToken,
            1000000000000000000, // 1e18
            500000000000000000 // 0.5e18
        );

        MockPair pair2 = new MockPair(
            wbnbToken,
            usdtToken,
            1000000000000000000, // 1e18
            3000000000000000000000 // 3000 USDT
        );

        console.log("MockPair deployed at:", address(pair));
        vm.stopBroadcast();
    }
}
