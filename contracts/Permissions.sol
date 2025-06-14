// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Permissions is Initializable, OwnableUpgradeable {
    enum Access { Create, Update, Remove, Read }
    mapping(address => mapping(Access => bool)) public userPermissions;

    function initialize() public initializer {
        __Ownable_init(msg.sender);
    }

    function setAccess(address user, Access accessLevel) external onlyOwner {
        userPermissions[user][accessLevel] = true;
    }

    function hasAccess(address user, Access accessLevel) external view returns (bool) {
        return userPermissions[user][accessLevel];
    }
}