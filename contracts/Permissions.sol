// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Permissions is Initializable, AccessControlUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");

    function initialize(address admin) public initializer {
        __AccessControl_init();
       grantRole(DEFAULT_ADMIN_ROLE, admin);
       grantRole(OPERATOR_ROLE, admin);
    }

    function grantOperator(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(OPERATOR_ROLE, account);
    }

    function revokeOperator(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(OPERATOR_ROLE, account);
    }

    function grantTreasurer(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(TREASURER_ROLE, account);
    }

    function revokeTreasurer(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(TREASURER_ROLE, account);
    }

    function hasOperator(address account) external view returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }

    function hasTreasurer(address account) external view returns (bool) {
        return hasRole(TREASURER_ROLE, account);
    }
}
