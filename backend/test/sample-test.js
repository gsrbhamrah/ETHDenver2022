const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Deploy coin", function () {
  it("Should return the symbol once the coin is deployed", async function () {
    const Coin = await ethers.getContractFactory("Coin");
    const coin = await Coin.deploy();
    await coin.deployed();

    expect(await coin.symbol()).to.equal("DAGE");
  });
});
