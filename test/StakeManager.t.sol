// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Test, console} from "forge-std/Test.sol";
import {StakeManager} from "../src/StakeManager.sol";

contract StakeManagerTest is Test {
    StakeManager public stakeManager;
    address public admin;
    address public user01;

    uint256 newDepositAmount = 2 ether;
    uint256 newWaitTime = 2 weeks;

    function setUp() public {
        admin = address(this);
        user01 = address(0xa0b0c0d0);
        vm.deal(user01, 100 ether);

        address proxy = Upgrades.deployUUPSProxy("StakeManager.sol", "");
        stakeManager = StakeManager(proxy);
        stakeManager.initialize();

        // Set configuration values
        vm.prank(admin);
        stakeManager.setConfiguration(newDepositAmount, newWaitTime);
    }

    function testSetConfiguration() public {
        // Verificar se a configuração foi atualizada
        (uint256 depositAmount, uint256 waitTime) = stakeManager.globalConfig();
        assertEq(depositAmount, newDepositAmount);
        assertEq(waitTime, newWaitTime);
    }

    function testRegister() public {
        vm.prank(user01);
        stakeManager.register{value: 2 ether}();

        // Verificar se o staker foi registrado corretamente
        (uint256 registrationTime, uint256 stakedAmount) = stakeManager
            .userStakeData(user01);
        assertTrue(registrationTime > 0);
        assertEq(stakedAmount, 0);
        assertTrue(stakeManager.hasRole(stakeManager.STAKER_ROLE(), user01));
    }

    function testStake() public {
        // Registrar primeiro
        vm.prank(user01);
        stakeManager.register{value: 2 ether}();

        // Stake funds
        vm.prank(user01);
        stakeManager.stake{value: 2 ether}();

        // Verificar se os fundos foram apostados corretamente
        (, uint256 stakedAmount) = stakeManager.userStakeData(user01);
        assertEq(stakedAmount, 2 ether);
    }

    function testSlash() public {
        // Registrar e stake primeiro
        vm.prank(user01);
        stakeManager.register{value: 2 ether}();
        vm.prank(user01);
        stakeManager.stake{value: 2 ether}();

        // Slash funds
        vm.prank(admin);
        stakeManager.slash(user01, 1 ether);

        // Verificar se os fundos foram slashed corretamente
        (, uint256 stakedAmount) = stakeManager.userStakeData(user01);
        assertEq(stakedAmount, 1 ether);

        // Verificar se os fundos foram transferidos para o treasury
        uint256 treasuryBalance = stakeManager.treasuryBalance();
        assertEq(treasuryBalance, 3 ether); // 2 ether de registro + 1 ether de slash

        //get the balance of the contract
        uint256 contractBalance = address(stakeManager).balance;
        assertEq(contractBalance, 4 ether);
    }

    function testUnstake() public {
        // Registrar e stake primeiro
        vm.startPrank(user01);

        stakeManager.register{value: 2 ether}();
        stakeManager.stake{value: 2 ether}();

        (uint registrationTime, ) = stakeManager.userStakeData(user01);
        vm.warp(registrationTime + newWaitTime);
        stakeManager.unstake();

        vm.stopPrank();

        // Verificar se os fundos foram desapostados corretamente
        (, uint256 stakedAmount) = stakeManager.userStakeData(user01);
        assertEq(stakedAmount, 0);
    }

    function testRevertIfUnstakeBeforeTimeLimit() public {
        // Registrar e stake primeiro
        vm.startPrank(user01);
        stakeManager.register{value: 2 ether}();
        stakeManager.stake{value: 2 ether}();

        vm.expectRevert("StakeManager: staker must wait before unstaking");
        stakeManager.unstake();

        vm.stopPrank();
    }

    function testUnregister() public {
        // Registrar primeiro
        vm.prank(user01);
        stakeManager.register{value: 2 ether}();

        // Desregistrar
        vm.prank(user01);
        stakeManager.unregister();

        // Verificar se o staker foi desregistrado
        (uint256 registrationTime, ) = stakeManager.userStakeData(user01);
        assertEq(registrationTime, 0);
        assertFalse(stakeManager.hasRole(stakeManager.STAKER_ROLE(), user01));
    }
}
