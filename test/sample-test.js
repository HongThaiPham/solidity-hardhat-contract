const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Contract upgraded", function () {
  it("works", async () => {
    const ContractV1 = await ethers.getContractFactory("ContractV1");
    const ContractV2 = await ethers.getContractFactory("ContractV2");

    const instance = await upgrades.deployProxy(ContractV1, [
      "Hello, Hardhat!",
    ]);

    let greet = await instance.greet();
    expect(greet.toString()).to.equal("Hello, Hardhat!");

    instance.setGreeting("Hello, Leo Pham!");
    greet = await instance.greet();
    expect(greet.toString()).to.equal("Hello, Leo Pham!");

    const upgraded = await upgrades.upgradeProxy(instance.address, ContractV2);

    [greet, time] = await upgraded.greet();
    console.log(`updateTime: ${time}`);
    expect(greet.toString()).to.equal("Hello, Leo Pham!");

    upgraded.setGreeting("Hello, Leo Pham upgraded!");

    [greet, time] = await upgraded.greet();
    console.log(`updateTime: ${time}`);
    expect(greet.toString()).to.equal("Hello, Leo Pham upgraded!");
  });
});
