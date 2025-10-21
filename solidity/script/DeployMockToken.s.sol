//SPDX-license-Identifier: MIT

pragma solidity ^0.8.20;
import {MockToken} from "../test/mocks/MockToken.sol";
import {Script} from "forge-std/Script.sol";

contract DeployMockToken is Script {
    function run() external returns (address) {
        vm.startBroadcast();
        MockToken token = new MockToken("Wrapped BNB", "WBNB");
        vm.stopBroadcast();

        return address(token);
    }
}
