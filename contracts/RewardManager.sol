// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract RewardManager is Initializable, OwnableUpgradeable {
    uint256 public platformFee;
    uint256 public maxRewardPoints;
    mapping(address => uint256) public userRewardPoints;

    event RewardDistributed(address indexed user, uint256 points);

    function initialize(uint256 _fee, uint256 _maxPoints) public initializer {
        __Ownable_init(msg.sender);
        platformFee = _fee;
        maxRewardPoints = _maxPoints;
    }

    function distributeReward(address user, uint256 amount, uint256 reward ) external  onlyOwner {
        require(amount > 0, "Amount must be > 0");
        userRewardPoints[user] += reward;
        emit RewardDistributed(user, reward);
    }

    function calculateReward(uint256 amount) external view returns (uint256) {
        uint256 reward = amount * platformFee / 10000;
        return reward > maxRewardPoints ? maxRewardPoints : reward;
    }
}
