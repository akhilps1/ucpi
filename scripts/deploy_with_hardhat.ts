import { ethers, upgrades } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with:", deployer.address);

  const Permissions = await ethers.getContractFactory("Permissions");
  const permissions = await upgrades.deployProxy(Permissions, [], {
    initializer: "initialize",
  });
  await permissions.waitForDeployment();
  const permissionsAddress = await permissions.getAddress();
  console.log("Permissions deployed to:", permissionsAddress);

  const RewardManager = await ethers.getContractFactory("RewardManager");
  const rewardManager = await upgrades.deployProxy(RewardManager, [100, 5000], {
    initializer: "initialize",
  });
  await rewardManager.waitForDeployment();
  const rewardManagerAddress = await rewardManager.getAddress();
  console.log("RewardManager deployed to:", rewardManagerAddress);

  const Logger = await ethers.getContractFactory("Logger");
  const logger = await upgrades.deployProxy(Logger, [], {
    initializer: "initialize",
  });
  await logger.waitForDeployment();
  const loggerAddress = await logger.getAddress();
  console.log("Logger deployed to:", loggerAddress);

  const UCPI = await ethers.getContractFactory("UCPI");
  const ucpi = await upgrades.deployProxy(
    UCPI,
    [permissionsAddress, rewardManagerAddress, loggerAddress],
    { initializer: "initialize" }
  );
  await ucpi.waitForDeployment();
  const ucpiAddress = await ucpi.getAddress();
  console.log("UCPI deployed to:", ucpiAddress);
}

main().catch((error) => {
  console.error(error);
  
});
