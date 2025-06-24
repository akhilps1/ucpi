// Ensure you have @types/node, @nomiclabs/hardhat-ethers, and @openzeppelin/hardhat-upgrades installed
// npm install --save-dev @types/node @nomiclabs/hardhat-ethers @openzeppelin/hardhat-upgrades
import { ethers, upgrades } from "hardhat";
// 'process' is globally available in Node.js, no need to import

async function main() {
    // 1. Deploy RewardToken (UCPI Coin) as a non-upgradeable contract
    const RewardToken = await ethers.getContractFactory("RewardToken");
    const initialOwner = "YOUR_OWNER_ADDRESS";
    const rewardToken = await RewardToken.deploy(initialOwner);
    await rewardToken.deployed();
    console.log("RewardToken deployed to:", rewardToken.address);

    // 2. Deploy Permissions as an upgradeable contract
    const Permissions = await ethers.getContractFactory("Permissions");
    const permissions = await upgrades.deployProxy(Permissions, [], { initializer: 'initialize', kind: 'uups' });
    await permissions.deployed();
    console.log("Permissions (proxy) deployed to:", permissions.address);

    // 3. Deploy Logger as an upgradeable contract
    const Logger = await ethers.getContractFactory("Logger");
    const logger = await upgrades.deployProxy(Logger, [], { initializer: 'initialize', kind: 'uups' });
    await logger.deployed();
    console.log("Logger (proxy) deployed to:", logger.address);

    // 4. Deploy RewardManager as an upgradeable contract
    const RewardManager = await ethers.getContractFactory("RewardManager");
    const platformFee = 500; // 5% (example)
    const maxPoints = ethers.utils.parseUnits("1000", 18); // Example max points
    const rewardManager = await upgrades.deployProxy(RewardManager, [platformFee, maxPoints], { initializer: 'initialize', kind: 'uups' });
    await rewardManager.deployed();
    console.log("RewardManager (proxy) deployed to:", rewardManager.address);

    // 5. Set RewardToken in RewardManager
    await rewardManager.setRewardToken(rewardToken.address);
    console.log("RewardToken set in RewardManager");

    // 6. Fund RewardManager with UCPC tokens
    // Only needed if you are the initial owner and have the tokens
    // const amount = ethers.utils.parseUnits("100000", 18); // Example amount
    // await rewardToken.transfer(rewardManager.address, amount);
    // console.log("RewardManager funded with UCPC tokens");

    // 7. Deploy UCPI as an upgradeable contract
    const UCPI = await ethers.getContractFactory("UCPI");
    const ucpi = await upgrades.deployProxy(UCPI, [permissions.address, rewardManager.address, logger.address], { initializer: 'initialize', kind: 'uups' });
    await ucpi.deployed();
    console.log("UCPI (proxy) deployed to:", ucpi.address);

    // 8. Set UCPI contract in RewardManager
    await rewardManager.setUCPIContract(ucpi.address);
    console.log("UCPI contract set in RewardManager");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
}); 