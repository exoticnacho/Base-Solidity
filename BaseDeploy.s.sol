// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import "../src/BaseToken.sol";
import "../src/BaseCertificate.sol";
import "../src/BaseBadge.sol";

contract BaseDeployScript is Script {
    BaseToken public token;
    BaseCertificate public certificate;
    BaseBadge public badge;

    function run() public {
        console.log("Starting deployment to Base Sepolia testnet...");
        console.log("");

        // Load deployer's private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployment Details:");
        console.log("Deployer address:", deployer);

        // Check balance
        uint256 balance = deployer.balance;
        console.log("Deployer balance:", balance / 1e18, "ETH");

        if (balance < 0.01 ether) {
            console.log("Warning: Low balance. Make sure you have enough ETH for deployment.");
        }

        console.log("Network: Base Sepolia Testnet");
        console.log("Chain ID: 84532");
        console.log("RPC URL: https://sepolia.base.org");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying BaseToken (ERC-20)...");
        token = new BaseToken(1_000_000 * 10 ** 18);
        console.log("BaseToken deployed at:", address(token));

        console.log("Deploying BaseCertificate (ERC-721 soulbound)...");
        certificate = new BaseCertificate();
        console.log("BaseCertificate deployed at:", address(certificate));

        console.log("Deploying BaseBadge (ERC-1155)...");
        badge = new BaseBadge();
        console.log("BaseBadge deployed at:", address(badge));

        // Grant MINTER_ROLE to deployer for token and badge contracts
        bytes32 MINTER_ROLE = keccak256("MINTER_ROLE");

        console.log("Granting MINTER_ROLE to deployer on BaseToken and BaseBadge...");
        token.grantRole(MINTER_ROLE, deployer);
        badge.grantRole(MINTER_ROLE, deployer);

        vm.stopBroadcast();

        console.log("");
        console.log("Deployment complete!");
        console.log("BaseToken address:", address(token));
        console.log("BaseCertificate address:", address(certificate));
        console.log("BaseBadge address:", address(badge));
        console.log("Deployer:", deployer);
    }
}
