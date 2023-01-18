import { expect } from "chai";
import { ethers } from "hardhat";

describe("Fileverse Portal Registry", function () {
  it("should be able to deploy with correct number of parameters", async function () {
    const FileversePortalRegistry = await ethers.getContractFactory(
      "FileversePortalRegistry"
    );

    const trustedForwarder = "0x7EF22F49a2aE4a2E7c20369E6F7E5C9f94238141";

    const fileversePortalRegistry = await FileversePortalRegistry.deploy(
      trustedForwarder
    );
    await fileversePortalRegistry.deployed();

    expect(await fileversePortalRegistry.name()).to.equal(
      "Fileverse Portal Registry"
    );
  });

  it("should be able to deploy with correct empty state", async function () {
    const FileversePortalRegistry = await ethers.getContractFactory(
      "FileversePortalRegistry"
    );

    const owner = "0x6b8ddbA9c380e68201F76072523C4aC9AC4113ae";
    const trustedForwarder = "0x7EF22F49a2aE4a2E7c20369E6F7E5C9f94238141";

    const fileversePortalRegistry = await FileversePortalRegistry.deploy(
      trustedForwarder
    );
    await fileversePortalRegistry.deployed();

    expect(await fileversePortalRegistry.name()).to.equal(
      "Fileverse Portal Registry"
    );
    expect(await fileversePortalRegistry.balancesOf(owner)).to.equal(0);
    const ownedPortals = await fileversePortalRegistry.ownedPortal(owner);
    expect(ownedPortals.length).to.equal(0);
    const allPortals = await fileversePortalRegistry.allPortal();
    expect(allPortals.length).to.equal(0);
  });
});
