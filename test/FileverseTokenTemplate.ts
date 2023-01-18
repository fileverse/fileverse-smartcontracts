import { expect } from "chai";
import { ethers } from "hardhat";

describe("Fileverse Token Template", function () {
  it("should deploy and confirm the name and symbol", async function () {
    const FileverseTokenTemplate = await ethers.getContractFactory(
      "FileverseTokenTemplate"
    );
    const _name = "FileverseNFT";
    const _symbol = "FNFT";
    const _ownerAddress = "0x6b8ddbA9c380e68201F76072523C4aC9AC4113ae";
    const _newBaseUri = "https://beta.fileverse.io";
    const fileverseNFT = await FileverseTokenTemplate.deploy(
      _name,
      _symbol,
      _ownerAddress,
      _newBaseUri
    );
    await fileverseNFT.deployed();

    expect(await fileverseNFT.name()).to.equal(_name);
    expect(await fileverseNFT.symbol()).to.equal(_symbol);
    console.log("name: ", await fileverseNFT.name());
    console.log("symbol:", await fileverseNFT.symbol());
  });
});
