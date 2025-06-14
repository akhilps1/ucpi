// scripts/deploy.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const UCPI = await ethers.getContractFactory("UCPI");
  const proxy = await upgrades.deployProxy(UCPI, [100], {
    initializer: "initialize",
    kind: "uups"
  });
  console.log("UCPI deployed at:", proxy.address);
}

main();
