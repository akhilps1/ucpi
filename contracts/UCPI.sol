// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./Permissions.sol";
import "./RewardManager.sol";
import "./Logger.sol";


contract UCPI is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    Permissions public permissions;
    RewardManager public rewardManager;
    Logger public logger;

    function initialize(address _permissions, address _rewardManager, address _logger) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        permissions = Permissions(_permissions);
        rewardManager = RewardManager(_rewardManager);
        logger = Logger(_logger);
        
        
    }

    function performAction(address user,  uint256 amount, uint48 timestamp, string calldata txHash, address token) external {
        require(permissions.hasAccess(msg.sender, Permissions.Access.Create), "No access");

        uint256 reward = rewardManager.calculateReward(amount);
        logger.logTransaction(timestamp, user, amount, amount * rewardManager.platformFee() / 10000, reward, txHash, token);
        rewardManager.distributeReward(user, amount, reward);
        
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
