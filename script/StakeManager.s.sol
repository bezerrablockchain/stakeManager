// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {StakeManager} from "../src/StakeManager.sol";

contract StakeManagerScript is Script {
    function setUp() public {}

    function run() public {
        uint privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        console.log("deployer", deployer);

        vm.startBroadcast(privateKey);
        StakeManager stakeManager = new StakeManager();
        vm.stopBroadcast();

        console.log("stakeManager deployed at: ", address(stakeManager));
    }
}
