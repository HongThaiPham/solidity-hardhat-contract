const { ethers } = require("hardhat");

const main = async () => {
  [owner, dev, bob, alice, ...addrs] = await ethers.getSigners();

  const CryptoHeroes = await ethers.getContractFactory("CryptoHeroes");
  const cryptoHeroesToken = await CryptoHeroes.deploy();

  const LPToken = await ethers.getContractFactory("LPToken");
  const lpToken = await LPToken.deploy("LPToken", "LP", 1000000);

  const NFTToken = await ethers.getContractFactory("CryptoHeroesNFT");
  const nftToken = await NFTToken.deploy();

  const PoolContract = await ethers.getContractFactory("CryptoHeroesPool");
  const poolContract = await PoolContract.deploy(
    cryptoHeroesToken.address,
    dev.address,
    100
  );

  await cryptoHeroesToken.transferOwnership(poolContract.address);

  await poolContract.addPool(
    2000,
    lpToken.address,
    true,
    false,
    nftToken.address
  );

  // chuyển lptoken cho alice, alice có lp
  await lpToken.transfer(alice.address, 2000);
  console.log(
    `lpToken: alice balance ${await lpToken.balanceOf(alice.address)}`
  );
  await lpToken.transfer(bob.address, 2000);
  console.log(`lpToken: bob balance ${await lpToken.balanceOf(bob.address)}`);

  // alice approve lptoken vào pool
  await lpToken.connect(alice).approve(poolContract.address, 1000);
  await lpToken.connect(bob).approve(poolContract.address, 1000);

  // alice chưa có heroes token
  console.log(
    `cryptoHeroesToken: alice balance ${await cryptoHeroesToken.balanceOf(
      alice.address
    )}`
  );
  console.log(
    `cryptoHeroesToken: bob balance ${await cryptoHeroesToken.balanceOf(
      bob.address
    )}`
  );

  // alice chuyển lptoken vào pool
  await poolContract.connect(alice).deposit(0, 200);
  await poolContract.connect(bob).deposit(0, 100);

  await mineNBlocks(5);

  await poolContract.connect(alice).withdraw(0, 200);
  await poolContract.connect(bob).withdraw(0, 100);
  // // alice có heroes token
  console.log(
    `cryptoHeroesToken: alice balance ${await cryptoHeroesToken.balanceOf(
      alice.address
    )}`
  );
  console.log(
    `cryptoHeroesToken: bob balance ${await cryptoHeroesToken.balanceOf(
      bob.address
    )}`
  );
};

async function mineNBlocks(n) {
  for (let index = 0; index < n; index++) {
    await ethers.provider.send("evm_mine");
  }
}

main();
