// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Deploy} from "../script/Deploy.s.sol";
import {console} from "forge-std/console.sol";

contract DeployerTest is Test {
    Deploy deployer;

    function setUp() public {
        deployer = new Deploy();
    }

    function testDeploy() public {
        vm.chainId(56); // 模拟主网链id

        (address vault, address oracle) = deployer.deployer(100);
        console.log("Vault deployed at:", vault);
        console.log("Oracle deployed at:", oracle);
    }
}
