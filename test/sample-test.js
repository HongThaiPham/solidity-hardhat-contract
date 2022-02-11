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
      100
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

      // chuyển lptoken cho alice, alice có lp
      await lpToken.transfer(alice.address, 2000);
      expect(await lpToken.balanceOf(alice.address)).to.equal(2000);

      await lpToken.transfer(bob.address, 2000);
      expect(await lpToken.balanceOf(bob.address)).to.equal(2000);

      // alice approve lptoken vào pool
      await lpToken.connect(alice).approve(poolContract.address, 1000);
      await lpToken.connect(bob).approve(poolContract.address, 1000);

      // alice chưa có heroes token
      expect(await cryptoHeroesToken.balanceOf(alice.address)).to.equal(0);
      expect(await cryptoHeroesToken.balanceOf(bob.address)).to.equal(0);

      // alice chuyển lptoken vào pool

      await poolContract.connect(alice).deposit(0, 200);
      // expect(await lpToken.balanceOf(alice.address)).to.equal(1900);
      // expect(await lpToken.balanceOf(poolContract.address)).to.equal(100);

      await poolContract.connect(bob).deposit(0, 500);

      // await time.advanceBlockTo("100");

      // alice rút lptoken khỏi pool

      setTimeout(async () => {
        await poolContract.connect(alice).withdraw(0, 200);
        await poolContract.connect(bob).withdraw(0, 500);
        // // alice có heroes token
        console.log(await cryptoHeroesToken.balanceOf(alice.address));
        console.log(await cryptoHeroesToken.balanceOf(bob.address));
      }, 5000);
    });
  });
});
