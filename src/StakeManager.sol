// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IStakeManager.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract StakeManager is
    IStakeManager,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant STAKER_ROLE = keccak256("STAKER_ROLE");

    struct GlobalConfig {
        uint256 registrationDepositAmount;
        uint256 registrationWaitTime;
    }

    struct UserStakeData {
        uint256 registrationTime;
        uint256 stakedAmount;
    }

    mapping(address => UserStakeData) public userStakeData;
    uint256 public treasuryBalance;

    GlobalConfig public globalConfig;

    event newRegistration(address indexed staker, uint256 registrationTime);
    event newUnregistration(address indexed staker);
    event newStake(address indexed staker, uint256 stakedAmount);
    event newUnstake(address indexed staker, uint256 unstakedAmount);
    event newSlash(address indexed staker, uint256 slashedAmount);
    event newWithdrawTreasury(address indexed admin, uint256 amount);

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function setConfiguration(
        uint256 registrationDepositAmount,
        uint256 registrationWaitTime
    ) external override onlyRole(ADMIN_ROLE) {
        globalConfig.registrationDepositAmount = registrationDepositAmount;
        globalConfig.registrationWaitTime = registrationWaitTime;
    }

    function register() external payable override {
        require(
            globalConfig.registrationWaitTime >= 1,
            'Global Config: wait until registrationWaitTime be set'
        );

        require(
            msg.value == globalConfig.registrationDepositAmount,
            "StakeManager: invalid registration deposit amount"
        );
        require(
            userStakeData[msg.sender].registrationTime == 0,
            "StakeManager: staker already registered"
        );

        userStakeData[msg.sender].registrationTime = block.timestamp;
        treasuryBalance += msg.value; //Assume that the registration deposit is sent to the treasury

        _grantRole(STAKER_ROLE, msg.sender);

        emit newRegistration(msg.sender, block.timestamp);
    }

    function unregister() external override onlyRole(STAKER_ROLE) {
        require(
            userStakeData[msg.sender].stakedAmount == 0,
            "StakeManager: staker must unstake before unregistering"
        );

        _revokeRole(STAKER_ROLE, msg.sender);
        userStakeData[msg.sender].registrationTime = 0;

        emit newUnregistration(msg.sender);
    }

    function stake() external payable override onlyRole(STAKER_ROLE) {
        userStakeData[msg.sender].stakedAmount += msg.value;

        emit newStake(msg.sender, msg.value);
    }

    function unstake() external override onlyRole(STAKER_ROLE) {
        require(
            userStakeData[msg.sender].stakedAmount > 0,
            "StakeManager: staker has no staked amount"
        );
        require(
            block.timestamp - userStakeData[msg.sender].registrationTime >=
                globalConfig.registrationWaitTime,
            "StakeManager: staker must wait before unstaking"
        );

        unchecked {
            uint256 stakedAmount = userStakeData[msg.sender].stakedAmount;
            userStakeData[msg.sender].stakedAmount = 0;
            payable(msg.sender).transfer(stakedAmount);
        }

        emit newUnstake(msg.sender, userStakeData[msg.sender].stakedAmount);
    }

    function slash(
        address staker,
        uint256 amount
    ) external override onlyRole(ADMIN_ROLE) {
        require(
            userStakeData[staker].stakedAmount >= amount,
            "StakeManager: staker has insufficient staked amount"
        );

        unchecked {
            userStakeData[staker].stakedAmount -= amount;
            treasuryBalance += amount; //Assume that the slashed amount is sent to the treasury
        }

        emit newSlash(staker, amount);
    }

    function withdrawTreasury(uint256 amount) external onlyRole(ADMIN_ROLE) {
        require(
            amount <= treasuryBalance,
            "StakeManager: insufficient treasury balance"
        );

        unchecked {
            treasuryBalance -= amount;
            payable(msg.sender).transfer(amount);
        }

        emit newWithdrawTreasury(msg.sender, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
