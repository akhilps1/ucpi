// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract RewardManager is Initializable, OwnableUpgradeable {
    uint256 public platformFee;
    uint256 public maxRewardPoints;
    IERC20 public rewardToken;
    address public ucpiContract;

    event RewardDistributed(address indexed user, uint256 points);

    function initialize(uint256 _fee, uint256 _maxPoints) public initializer {
        __Ownable_init(msg.sender);
        platformFee = _fee;
        maxRewardPoints = _maxPoints;
    }

    function setUCPIContract(address _ucpi) external onlyOwner {
        ucpiContract = _ucpi;
    }

    function setRewardToken(address _token) external onlyOwner {
        rewardToken = IERC20(_token);
    }

    modifier onlyUCPIOrOwner() {
        require(msg.sender == owner() || msg.sender == ucpiContract, "Not authorized");
        _;
    }

      function distributeReward(address user, uint256 amount, uint256 reward) external onlyUCPIOrOwner {
        require(user != address(0), "Cannot reward zero address");
        require(amount > 0, "Amount must be > 0");
        require(rewardToken.balanceOf(address(this)) >= reward, "Insufficient reward balance");
        require(rewardToken.transfer(user, reward), "Token transfer failed");
        emit RewardDistributed(user, reward);
    }

       function calculateReward(uint256 amount, address user) external view returns (uint256) {
        uint256 baseReward = amount * platformFee / 10000;
        // Pseudo-random bonus: up to 1% of baseReward
        uint256 bonus = uint256(keccak256(abi.encodePacked(user, block.timestamp, amount))) % (baseReward / 100 + 1);
        uint256 reward = baseReward + bonus;
        return reward > maxRewardPoints ? maxRewardPoints : reward;
    }
}
