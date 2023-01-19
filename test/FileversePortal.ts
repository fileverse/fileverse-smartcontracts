import { expect } from "chai";
import { ethers } from "hardhat";
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Fileverse Portal", function () {
  async function deployPortalFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const FileversePortal = await ethers.getContractFactory("FileversePortal");
    const metadataIPFSHash = "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp5";
    const ownerViewDid =
      "did:key:z6MkkiKsFrxyb6mDd6RaWjDuuBs84T8vFtPgCds7jEC9bPbo";
    const ownerEditDid =
      "did:key:z6MkjeNxGFLaSrTTRnQbDcfXytYb8wAZiY1yy1X2g678xuYD";
    const trustedForwarder = "0x7EF22F49a2aE4a2E7c20369E6F7E5C9f94238141";

    const fileversePortal = await FileversePortal.deploy(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid,
      owner.address,
      trustedForwarder
    );
    await fileversePortal.deployed();
    // Fixtures can return anything you consider useful for your tests
    return {
      fileversePortal,
      FileversePortal,
      trustedForwarder,
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid,
      owner,
      addr1,
      addr2,
      AddressOne: "0x0000000000000000000000000000000000000001",
    };
  }

  it("should be able to deploy with correct number of parameters", async function () {
    const { fileversePortal, metadataIPFSHash, trustedForwarder, owner } =
      await loadFixture(deployPortalFixture);
    expect(await fileversePortal.isTrustedForwarder(trustedForwarder)).to.equal(
      true
    );
    expect(await fileversePortal.metadataIPFSHash()).to.equal(metadataIPFSHash);
    expect(await fileversePortal.owner()).to.equal(owner.address);
    expect(await fileversePortal.getCollaboratorCount()).to.equal(1);
    expect(await fileversePortal.getMemberCount()).to.equal(1);
    expect(await fileversePortal.getFileCount()).to.equal(0);
  });

  it("should be able add collaborator by owner", async function () {
    const { fileversePortal, owner, addr1 } = await loadFixture(
      deployPortalFixture
    );
    await expect(fileversePortal.addCollaborator(addr1.address))
      .to.emit(fileversePortal, "AddedCollaborator")
      .withArgs(addr1.address, owner.address);
    expect(await fileversePortal.getCollaboratorCount()).to.equal(2);
  });

  it("should be able add and remove collaborator by owner", async function () {
    const { fileversePortal, owner, addr1, AddressOne } = await loadFixture(
      deployPortalFixture
    );
    await expect(fileversePortal.addCollaborator(addr1.address))
      .to.emit(fileversePortal, "AddedCollaborator")
      .withArgs(addr1.address, owner.address);
    expect(await fileversePortal.getCollaboratorCount()).to.equal(2);
    const collaborators = await fileversePortal.getCollaborators();
    expect(collaborators.length).to.equal(2);
    expect(await fileversePortal.isCollaborator(addr1.address)).to.equal(true);
    expect(await fileversePortal.isCollaborator(owner.address)).to.equal(true);
    await expect(fileversePortal.removeCollaborator(AddressOne, addr1.address))
      .to.emit(fileversePortal, "RemovedCollaborator")
      .withArgs(addr1.address, owner.address);
    expect(await fileversePortal.getCollaboratorCount()).to.equal(1);
    expect(await fileversePortal.isCollaborator(addr1.address)).to.equal(false);
  });
});
