// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract Logger is Initializable, OwnableUpgradeable {
    struct Transaction {
        address sender;
        address recipient;
        uint256 amount;
        uint256 fee;
        uint256 reward;
        uint48 timestamp;
        string txHash;
        address token;
    }

    mapping(address => Transaction[]) public userTransactions;

    event TransactionLogged(address indexed sender, address indexed recipient, uint256 amount);

    function initialize() public initializer {
        __Ownable_init(msg.sender);
    }

    function logTransaction(uint48 timestamp, address recipient,   uint256 amount, uint256 fee, uint256 reward, string calldata txHash, address token) external {
        require(recipient != address(0) && token != address(0), "Invalid address");
        userTransactions[msg.sender].push(Transaction({
            sender: msg.sender,
            recipient: recipient,
            amount: amount,
            fee: fee,
            reward: reward,
            timestamp: timestamp,
            txHash: txHash,
            token: token
        }));
        emit TransactionLogged(msg.sender, recipient, amount);
    }
}
