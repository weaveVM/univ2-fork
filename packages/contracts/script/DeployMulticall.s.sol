// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "../test/mocks/Multicall.sol";

contract DeployMulticall is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Multicall multicall = new Multicall();
        console.log("Multicall deployed at:", address(multicall));

        vm.stopBroadcast();
    }
}