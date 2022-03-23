import { expect } from "chai";
import { ethers } from "hardhat";

describe("FileverseNFT", function () {
  it("Should confirm the name and symbol", async function () {
    const FileverseNFT = await ethers.getContractFactory("FileverseNFT");
    const _name = "FileverseNFT";
    const _symbol = "FNFT";
    const fileverseNFT = await FileverseNFT.deploy(_name, _symbol);
    await fileverseNFT.deployed();

    expect(await fileverseNFT.name()).to.equal(_name);
    expect(await fileverseNFT.symbol()).to.equal(_symbol);
    console.log("name: ", await fileverseNFT.name());
    console.log("symbol:", await fileverseNFT.symbol());
  });
});
