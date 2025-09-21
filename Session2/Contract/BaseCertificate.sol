// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BaseCertificate
 * @dev NFT-Base certificate system for achievements, graduation, or training
 * Features:
 * - Soulbound (non-transferable)
 * - Metadata for certificate details
 * - Issuer-controlled (onlyOwner)
 */
contract BaseCertificate is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    uint256 private _nextTokenId;

    struct CertificateData {
        string recipientName;
        string course;
        string issuer;
        uint256 issuedDate;
        bool valid;
    }

    // --- Mappings ---
    // TODO: Add mappings
    // mapping(uint256 => CertificateData) public certificates;
    // mapping(address => uint256[]) public ownerCertificates; // Track all certs per owner
    // mapping(string => uint256) public certHashToTokenId; // Prevent duplicate certificate by hash
        
    mapping(uint256 => CertificateData) public certificates;
    mapping(address => uint256[]) public ownerCertificates;
    mapping(string => uint256) public certHashToTokenId;


    // --- Events ---
    event CertificateIssued(
        uint256 indexed tokenId,
        address recipient,
        string course,
        string issuer
    );
    event CertificateRevoked(uint256 indexed tokenId);
    event CertificateUpdated(uint256 indexed tokenId, string newCourse);

    constructor() ERC721("Base Certificate", "BCERT") Ownable(msg.sender) {}

    /**
     * @dev Issue a new certificate
     * Use case: Awarding completion or graduation
     */
    function issueCertificate(
        address to,
        string memory recipientName,
        string memory course,
        string memory issuer,
        string memory uri
    ) public onlyOwner {
        // TODO: Implement issuance
        // 1. Check duplicate (optional: via hash)
        // 2. Mint new NFT
        // 3. Set token URI (certificate metadata file)
        // 4. Save certificate data
        // 5. Update mappings
        // 6. Emit event

        string memory certHash = string(abi.encodePacked(recipientName, course, issuer));
        require(certHashToTokenId[certHash] == 0, "Certificate already exists");

        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);

        certificates[tokenId] = CertificateData({
            recipientName: recipientName,
            course: course,
            issuer: issuer,
            issuedDate: block.timestamp,
            valid: true
        });

        ownerCertificates[to].push(tokenId);
        certHashToTokenId[certHash] = tokenId;

        emit CertificateIssued(tokenId, to, course, issuer);
    }

    /**
     * @dev Revoke a certificate (e.g. if mistake or fraud)
     */
    function revokeCertificate(uint256 tokenId) public onlyOwner {
        // TODO: Check token exists
        // Mark certificate invalid
        // Emit event
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        certificates[tokenId].valid = false;
        emit CertificateRevoked(tokenId);
    }

    /**
     * @dev Update certificate data (optional, for corrections)
     */
    function updateCertificate(uint256 tokenId, string memory newCourse) public onlyOwner {
        // TODO: Check token exists
        // Update course field
        // Emit event
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        certificates[tokenId].course = newCourse;
        emit CertificateUpdated(tokenId, newCourse);
    }

    /**
     * @dev Get all certificates owned by an address
     */
    function getCertificatesByOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        // TODO: Return certificate Base on owner
        return ownerCertificates[owner];
    }
    
    /**
    * @dev Burn a certificate (soulbound cleanup)
    */
    function burnCertificate(uint256 tokenId) public onlyOwner {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "Token does not exist");

        certificates[tokenId].valid = false;
     
        _burn(tokenId);
    }

    /**
     * @dev Override transfer functions to make non-transferable (soulbound)
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns(address){
        // TODO: Only allow minting (from == address(0)) and burning (to == address(0))
        // require(from == address(0) || to == address(0), "Certificates are non-transferable");
        // super._update(to, tokenId, auth);
        address from = _ownerOf(tokenId);
        require(
            from == address(0) || to == address(0),
            "Certificate is non-transferable"
        );
        return super._update(to, tokenId, auth);
    }

    // --- Overrides for multiple inheritance ---

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
