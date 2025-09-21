// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title BaseBadge
 * @dev ERC1155 multi-token for badges, certificates, and achievements
 */
contract BaseBadge is ERC1155, AccessControl, Pausable, ERC1155Supply {
    // --- Roles ---
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // --- Token ID ranges ---
    uint256 public constant CERTIFICATE_BASE = 1000;
    uint256 public constant EVENT_BADGE_BASE = 2000;
    uint256 public constant ACHIEVEMENT_BASE = 3000;
    uint256 public constant WORKSHOP_BASE = 4000;

    // --- Token Info ---
    struct TokenInfo {
        string name;
        string category;
        uint256 maxSupply;
        bool isTransferable;
        uint256 validUntil; // 0 = no expiry
        address issuer;
    }

    mapping(uint256 => TokenInfo) public tokenInfo;
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256[]) public holderTokens;
    mapping(uint256 => mapping(address => uint256)) public earnedAt;

    // --- ID Counters ---
    uint256 private _certificateCounter;
    uint256 private _eventCounter;
    uint256 private _achievementCounter;
    uint256 private _workshopCounter;

    // --- Events ---
    event TokenTypeCreated(uint256 indexed tokenId, string name, string category);
    event BadgeIssued(uint256 indexed tokenId, address to);
    event BatchBadgesIssued(uint256 indexed tokenId, uint256 count);
    event AchievementGranted(uint256 indexed tokenId, address student, string achievement);

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function createBadgeType(
        string memory name,
        string memory category,
        uint256 maxSupply,
        bool transferable,
        string memory tokenUri
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 tokenId;

        if (keccak256(bytes(category)) == keccak256(bytes("certificate"))) {
            _certificateCounter++;
            tokenId = CERTIFICATE_BASE + _certificateCounter;
        } else if (keccak256(bytes(category)) == keccak256(bytes("event"))) {
            _eventCounter++;
            tokenId = EVENT_BADGE_BASE + _eventCounter;
        } else if (keccak256(bytes(category)) == keccak256(bytes("achievement"))) {
            _achievementCounter++;
            tokenId = ACHIEVEMENT_BASE + _achievementCounter;
        } else if (keccak256(bytes(category)) == keccak256(bytes("workshop"))) {
            _workshopCounter++;
            tokenId = WORKSHOP_BASE + _workshopCounter;
        } else {
            revert("Unknown category");
        }

        tokenInfo[tokenId] = TokenInfo(name, category, maxSupply, transferable, 0, msg.sender);
        _tokenURIs[tokenId] = tokenUri;

        emit TokenTypeCreated(tokenId, name, category);
        return tokenId;
    }

    function issueBadge(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        require(tokenInfo[tokenId].issuer != address(0), "Token doesn't exist");
        require(totalSupply(tokenId) + 1 <= tokenInfo[tokenId].maxSupply, "Max supply exceeded");

        _mint(to, tokenId, 1, "");
        earnedAt[tokenId][to] = block.timestamp;
        holderTokens[to].push(tokenId);

        emit BadgeIssued(tokenId, to);
    }

    function batchIssueBadges(address[] memory recipients, uint256 tokenId, uint256 amount)
        public onlyRole(MINTER_ROLE)
    {
        require(exists(tokenId), "Token doesn't exist");
        uint256 totalToMint = recipients.length * amount;
        require(totalSupply(tokenId) + totalToMint <= tokenInfo[tokenId].maxSupply, "Max supply exceeded");

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], tokenId, amount, "");
            earnedAt[tokenId][recipients[i]] = block.timestamp;
            holderTokens[recipients[i]].push(tokenId);
        }

        emit BatchBadgesIssued(tokenId, recipients.length);
    }

    function grantAchievement(address student, string memory achievementName, uint256 rarity)
        public onlyRole(MINTER_ROLE) returns (uint256)
    {
        _achievementCounter++;
        uint256 tokenId = ACHIEVEMENT_BASE + _achievementCounter;

        tokenInfo[tokenId] = TokenInfo(achievementName, "achievement", rarity, false, 0, msg.sender);
        _mint(student, tokenId, 1, "");
        earnedAt[tokenId][student] = block.timestamp;
        holderTokens[student].push(tokenId);

        emit AchievementGranted(tokenId, student, achievementName);
        return tokenId;
    }

    function createWorkshop(string memory seriesName, uint256 totalSessions)
        public onlyRole(MINTER_ROLE) returns (uint256[] memory)
    {
        uint256[] memory sessionIds = new uint256[](totalSessions);

        for (uint256 i = 0; i < totalSessions; i++) {
            _workshopCounter++;
            uint256 tokenId = WORKSHOP_BASE + _workshopCounter;
            sessionIds[i] = tokenId;

            tokenInfo[tokenId] = TokenInfo(
                string.concat(seriesName, " - Session ", Strings.toString(i + 1)),
                "workshop",
                1000,
                true,
                0,
                msg.sender
            );
        }

        return sessionIds;
    }

    function setURI(uint256 tokenId, string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _tokenURIs[tokenId] = newuri;
    }

    function getTokensByHolder(address holder) public view returns (uint256[] memory) {
        return holderTokens[holder];
    }

    function verifyBadge(address holder, uint256 tokenId)
        public view returns (bool valid, uint256 earnedTimestamp)
    {
        if (balanceOf(holder, tokenId) == 0) return (false, 0);
        uint256 timestamp = earnedAt[tokenId][holder];
        if (tokenInfo[tokenId].validUntil > 0 && block.timestamp > tokenInfo[tokenId].validUntil) {
            return (false, timestamp);
        }
        return (true, timestamp);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        require(!paused(), "Token transfer while paused");

        if (from != address(0) && to != address(0)) {
            for (uint i = 0; i < ids.length; i++) {
                require(tokenInfo[ids[i]].isTransferable, "This token is non-transferable");
            }
        }

        super._update(from, to, ids, values);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
