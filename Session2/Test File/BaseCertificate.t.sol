// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/BaseCertificate.sol";

contract BaseCertificateTest is Test {
    BaseCertificate cert;
    address owner;
    address alice;
    address bob;

    function setUp() public {
        owner = address(this);
        alice = address(0x1);
        bob = address(0x2);

        cert = new BaseCertificate();
    }

    function testIssueCertificate() public {
        cert.issueCertificate(alice, "Alice", "Solidity Course", "Based Academy", "ipfs://tokenURI1");

        uint256[] memory tokens = cert.getCertificatesByOwner(alice);
        assertEq(tokens.length, 1);

        // Memanggil fungsi helper untuk mendapatkan data sertifikat.
        (, string memory course,,,) = getCertificateData(tokens[0]);
        assertEq(course, "Solidity Course");
    }

    function testCannotIssueDuplicateCertificate() public {
        cert.issueCertificate(alice, "Alice", "Solidity Course", "Based Academy", "ipfs://tokenURI1");

        vm.expectRevert("Certificate already exists");
        cert.issueCertificate(alice, "Alice", "Solidity Course", "Based Academy", "ipfs://tokenURI1");
    }

    function testRevokeCertificate() public {
        cert.issueCertificate(alice, "Alice", "Solidity Course", "Based Academy", "ipfs://tokenURI1");

        uint256[] memory tokens = cert.getCertificatesByOwner(alice);
        uint256 tokenId = tokens[0];

        cert.revokeCertificate(tokenId);

        // Memverifikasi bahwa sertifikat tidak lagi valid setelah dicabut.
        (, , , , bool valid) = getCertificateData(tokenId);
        assertTrue(!valid);
    }

    function testUpdateCertificate() public {
        cert.issueCertificate(alice, "Alice", "Solidity Course", "Based Academy", "ipfs://tokenURI1");

        uint256[] memory tokens = cert.getCertificatesByOwner(alice);
        uint256 tokenId = tokens[0];

        cert.updateCertificate(tokenId, "Advanced Solidity");
        (, string memory course,,,) = getCertificateData(tokenId);

        assertEq(course, "Advanced Solidity");
    }

    function testSoulboundTransferFails() public {
        cert.issueCertificate(alice, "Alice", "Solidity Course", "Based Academy", "ipfs://tokenURI1");
        uint256[] memory tokens = cert.getCertificatesByOwner(alice);
        uint256 tokenId = tokens[0];

        vm.prank(alice);
        vm.expectRevert("BasedCertificate: token is soulbound and non-transferable");
        cert.transferFrom(alice, bob, tokenId);
    }

    // Fungsi helper untuk mengambil data sertifikat dari kontrak
    function getCertificateData(uint256 tokenId) internal view returns (
        string memory recipientName,
        string memory course,
        string memory issuer,
        uint256 issuedDate,
        bool valid
    ) {
        (recipientName, course, issuer, issuedDate, valid) = cert.certificates(tokenId);
    }
}
