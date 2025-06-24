// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Permissions.sol";
import "./RewardManager.sol";
import "./Logger.sol";


contract UCPI is Initializable, UUPSUpgradeable, OwnableUpgradeable, AccessControlUpgradeable {
    Permissions public permissions;
    RewardManager public rewardManager;
    Logger public logger;
    address public treasury;

    mapping(address => uint256) public lastActionTimestamp;
    uint256 public minInterval;
    uint256 public maxGasPrice;

    event TreasuryChanged(address indexed oldTreasury, address indexed newTreasury);
    event MinIntervalChanged(uint256 oldInterval, uint256 newInterval);
    event MaxGasPriceChanged(uint256 oldPrice, uint256 newPrice);

    function initialize(address _permissions, address _rewardManager, address _logger) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        permissions = Permissions(_permissions);
        rewardManager = RewardManager(_rewardManager);
        logger = Logger(_logger);
    }

    function setTreasury(address _treasury) external onlyRole(permissions.TREASURER_ROLE()) {
        address oldTreasury = treasury;
        treasury = _treasury;
        emit TreasuryChanged(oldTreasury, _treasury);
    }

    function setMinInterval(uint256 _interval) external onlyRole(permissions.DEFAULT_ADMIN_ROLE()) {
        uint256 oldInterval = minInterval;
        minInterval = _interval;
        emit MinIntervalChanged(oldInterval, _interval);
    }

    function setMaxGasPrice(uint256 _maxGasPrice) external onlyRole(permissions.DEFAULT_ADMIN_ROLE()) {
        uint256 oldPrice = maxGasPrice;
        maxGasPrice = _maxGasPrice;
        emit MaxGasPriceChanged(oldPrice, _maxGasPrice);
    }

    modifier gasPriceCap() {
        require(tx.gasprice <= maxGasPrice, "Gas price exceeds cap");
        _;
    }

    function performTransaction(address recipient, uint256 amount, uint48 timestamp, string calldata txHash, address token) external payable gasPriceCap onlyRole(permissions.OPERATOR_ROLE()) {
        require(recipient != address(0), "Invalid recipient");
        require(block.timestamp - lastActionTimestamp[msg.sender] >= minInterval, "Rate limit: wait before next action");
        lastActionTimestamp[msg.sender] = block.timestamp;

        uint256 fee = amount * rewardManager.platformFee() / 10000;
        uint256 netAmount = amount - fee;
        uint256 reward = rewardManager.calculateReward(amount, recipient);

        if (token == address(0)) {
            // ETH payment
            require(msg.value == amount, "Incorrect ETH sent");
            if (fee > 0 && treasury != address(0)) {
                payable(treasury).transfer(fee);
            }
            payable(recipient).transfer(netAmount);
        } else {
            // ERC20 payment
            require(IERC20(token).transferFrom(msg.sender, address(this), amount), "ERC20 transfer failed");
            if (fee > 0 && treasury != address(0)) {
                require(IERC20(token).transfer(treasury, fee), "Fee transfer failed");
            }
            require(IERC20(token).transfer(recipient, netAmount), "Recipient transfer failed");
        }

        logger.logTransaction(
            timestamp,
            recipient,
            amount,
            fee,
            reward,
            txHash,
            token
        );
        rewardManager.distributeReward(recipient, amount, reward);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
