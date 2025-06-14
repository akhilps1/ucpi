// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC-20 Interface
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract PlatformFeeAndRewardSystem {
    address public owner; // Admin
    uint256 public platformFee; // Platform fee in basis points (100 = 1%)
    uint256 public minRewardPoints;
    uint256 public maxRewardPoints;

    // Struct to store transaction details
    struct Transaction {
        address sender;
        address recipient;
        uint256 amount;
        uint256 feeAmount;
        uint256 rewardAmount;
        uint256 timestamp;
        string transactionHash;
        address tokenAddress;  // Address of the token (ERC-20)
    }

    mapping(address => uint256) public userRewardPoints;
    mapping(address => bool) public flaggedUsers;
    mapping(address => Transaction[]) public userTransactions; // Store transactions by user

    event FeeUpdated(uint256 newFee);
    event RewardDistributed(address indexed user, uint256 amount);
    event UserFlagged(address indexed user, string reason);
    event FeeCollected(address indexed user, uint256 feeAmount);
    event TransactionLogged(address indexed sender, address indexed recipient, uint256 amount, uint256 feeAmount, uint256 rewardAmount, uint256 timestamp, address tokenAddress);

    // Constructor sets the initial owner and platform fee
    constructor(uint256 _platformFee, uint256 _minRewardPoints, uint256 _maxRewardPoints) {
        owner = msg.sender;
        platformFee = _platformFee;
        minRewardPoints = _minRewardPoints;
        maxRewardPoints = _maxRewardPoints;
    }

    // Only admin can call certain functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Only admin can perform this action");
        _;
    }

    // Set the platform fee (admin only)
    function setPlatformFee(uint256 _newFee) external onlyOwner {
        platformFee = _newFee;
        emit FeeUpdated(_newFee);
    }

    // Set the reward point range (admin only)
    function setRewardPointsRange(uint256 _minPoints, uint256 _maxPoints) external onlyOwner {
        minRewardPoints = _minPoints;
        maxRewardPoints = _maxPoints;
    }

    // Calculate and distribute reward points based on the transaction
    function distributeReward(address user, uint256 transactionAmount) external onlyOwner {
        require(transactionAmount > 0, "Transaction amount must be greater than 0");
        
        uint256 rewardPoints = calculateRewardPoints(transactionAmount);
        
        // Update the user reward points
        userRewardPoints[user] += rewardPoints;
        
        // Emit the event
        emit RewardDistributed(user, rewardPoints);
    }

    // Calculate reward points based on transaction amount
    function calculateRewardPoints(uint256 transactionAmount) internal view returns (uint256) {
        uint256 reward = transactionAmount * platformFee / 10000; // Calculate reward
        if (reward < minRewardPoints) {
            return minRewardPoints;
        }
        if (reward > maxRewardPoints) {
            return maxRewardPoints;
        }
        return reward;
    }

    // Flag suspicious users (admin only)
    function flagUser(address user, string calldata reason) external onlyOwner {
        flaggedUsers[user] = true;
        emit UserFlagged(user, reason);
    }

    // Unflag a suspicious user (admin only)
    function unflagUser(address user) external onlyOwner {
        flaggedUsers[user] = false;
    }

    // Collect platform fee (for ETH transactions)
    function collectFee(uint256 transactionAmount) external {
        uint256 feeAmount = transactionAmount * platformFee / 10000;
        require(feeAmount > 0, "Fee amount must be greater than 0");

        // Transfer the fee to the platform (owner)
        payable(owner).transfer(feeAmount);
        emit FeeCollected(msg.sender, feeAmount);
    }

    // Collect platform fee for ERC-20 tokens
    function collectFeeERC20(address tokenAddress, uint256 transactionAmount) external {
        uint256 feeAmount = transactionAmount * platformFee / 10000;
        require(feeAmount > 0, "Fee amount must be greater than 0");

        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(owner, feeAmount), "Fee transfer failed");
        emit FeeCollected(msg.sender, feeAmount);
    }

    // Log transaction details (ETH or ERC-20)
    function logTransaction(address recipient, uint256 amount, uint256 feeAmount, uint256 rewardAmount, string calldata txHash, address tokenAddress) external {
        require(amount > 0, "Transaction amount must be greater than 0");

        // Store transaction details for the sender
        userTransactions[msg.sender].push(Transaction({
            sender: msg.sender,
            recipient: recipient,
            amount: amount,
            feeAmount: feeAmount,
            rewardAmount: rewardAmount,
            timestamp: block.timestamp,
            transactionHash: txHash,
            tokenAddress: tokenAddress
        }));

        // Emit the event to log the transaction
        emit TransactionLogged(msg.sender, recipient, amount, feeAmount, rewardAmount, block.timestamp, tokenAddress);
    }

    // Withdraw contract balance (only owner)
    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // Receive function to accept ETH sent to the contract
    receive() external payable {}

    // Withdraw ERC-20 token balance (only owner)
    function withdrawERC20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner, balance), "Transfer failed");
    }
}
