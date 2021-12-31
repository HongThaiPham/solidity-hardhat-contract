const { ethers, upgrades } = require("hardhat");

async function main() {
  const ContractV1 = await ethers.getContractFactory("ContractV1");
  const instanceV1 = await upgrades.deployProxy(ContractV1, [
    "Hello, Hardhat!",
  ]);

  await instanceV1.deployed();

  console.log("instanceV1 deployed to:", instanceV1.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
