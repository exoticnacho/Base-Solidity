// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title BaseToken
 * @dev ERC20 token with pausing, blacklist, daily claim, and access control.
 */
contract BaseToken is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    mapping(address => bool) public blacklisted;
    mapping(address => uint256) public lastClaim;

    constructor(uint256 initialSupply) ERC20("BaseToken", "BASE") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setBlacklist(address user, bool status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        blacklisted[user] = status;
    }

    function claimReward() public {
        require(!blacklisted[msg.sender], "Blacklisted");
        require(block.timestamp - lastClaim[msg.sender] >= 1 days, "Wait 24h");

        uint256 rewardAmount = 10 * 10 ** decimals();
        _mint(msg.sender, rewardAmount);
        lastClaim[msg.sender] = block.timestamp;
    }

    /**
     * @dev Hook to restrict transfers (paused or blacklisted)
     */
    function _update(address from, address to, uint256 value)
        internal
        override
        whenNotPaused
    {
        require(!blacklisted[from], "Sender is blacklisted");
        require(!blacklisted[to], "Receiver is blacklisted");

        super._update(from, to, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}