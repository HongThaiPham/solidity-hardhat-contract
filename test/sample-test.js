const { expectRevert, time } = require("@openzeppelin/test-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Transactions", function () {
  let cryptoHeroesToken;
  let lpToken;
  let poolContract;
  let nftToken;
  beforeEach(async () => {
    [owner, dev, bob, alice, ...addrs] = await ethers.getSigners();

    const CryptoHeroes = await ethers.getContractFactory("CryptoHeroes");
    cryptoHeroesToken = await CryptoHeroes.deploy();

    const LPToken = await ethers.getContractFactory("LPToken");
    lpToken = await LPToken.deploy("LPToken", "LP", 1000000);

    const NFTToken = await ethers.getContractFactory("CryptoHeroesNFT");
    nftToken = await NFTToken.deploy();

    const PoolContract = await ethers.getContractFactory("CryptoHeroesPool");
    poolContract = await PoolContract.deploy(
      cryptoHeroesToken.address,
      dev.address,
      1000
    );

    await cryptoHeroesToken.transferOwnership(poolContract.address);
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await cryptoHeroesToken.owner()).to.equal(poolContract.address);
    });

    it("Should assign the total supply of tokens to the owner", async function () {
      const ownerBalance = await cryptoHeroesToken.balanceOf(owner.address);
      expect(await cryptoHeroesToken.totalSupply()).to.equal(ownerBalance);
    });
  });

  // describe("transferOwnership", function () {
  //   it("Should change ownership to poolContract", async function () {
  //     await cryptoHeroesToken.transferOwnership(poolContract.address);
  //     expect(await cryptoHeroesToken.owner()).to.equal(poolContract.address);
  //   });
  // });
  describe("Real case", function () {
    it("should add new pool", async () => {
      await poolContract.addPool(
        2000,
        lpToken.address,
        true,
        false,
        nftToken.address
      );
      expect(await poolContract.poolLength()).to.equal(1);
    });
    it("should can deposit and withdraw", async () => {
      await poolContract.addPool(
        2000,
        lpToken.address,
        true,
        false,
        nftToken.address
      );

      await lpToken.transfer(alice.address, 2000);
      expect(await lpToken.balanceOf(alice.address)).to.equal(2000);
      await lpToken.connect(alice).approve(poolContract.address, 1000);
      expect(await cryptoHeroesToken.balanceOf(alice.address)).to.equal(0);
      await poolContract.connect(alice).deposit(0, 100);
      expect(await lpToken.balanceOf(alice.address)).to.equal(1900);
      await poolContract.connect(alice).withdraw(0, 100);
      console.log(await cryptoHeroesToken.balanceOf(alice.address));
    });
  });
});
