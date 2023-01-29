import { expect } from "chai";
import { ethers } from "hardhat";
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Fileverse Portal: Owner", function () {
  async function deployPortalFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const FileversePortal = await ethers.getContractFactory("FileversePortal");
    const metadataIPFSHash = "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp5";
    const ownerViewDid =
      "did:key:z6MkkiKsFrxyb6mDd6RaWjDuuBs84T8vFtPgCds7jEC9bPbo";
    const ownerEditDid =
      "did:key:z6MkjeNxGFLaSrTTRnQbDcfXytYb8wAZiY1yy1X2g678xuYD";
    const trustedForwarder = "0x7EF22F49a2aE4a2E7c20369E6F7E5C9f94238141";
    const keyVerifier = {
      portalEncryptionKeyVerifier:
        "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969",
      portalDecryptionKeyVerifier:
        "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969",
      memberEncryptionKeyVerifier:
        "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969",
      memberDecryptionKeyVerifier:
        "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969",
    };

    const fileversePortal = await FileversePortal.deploy(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid,
      owner.address,
      trustedForwarder,
      keyVerifier
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
      ipfsHash: "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp6",
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

  it("should be collaborator by default", async function () {
    const { fileversePortal, owner } = await loadFixture(deployPortalFixture);
    expect(await fileversePortal.isCollaborator(owner.address)).to.equal(true);
  });

  it("should be member by default", async function () {
    const { fileversePortal, owner, ownerViewDid, ownerEditDid } =
      await loadFixture(deployPortalFixture);
    const member = await fileversePortal.members(owner.address);
    expect(member.editDid).to.equal(ownerEditDid);
    expect(member.viewDid).to.equal(ownerViewDid);
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

  it("should be able to update metadata", async function () {
    const { fileversePortal, ipfsHash, owner } = await loadFixture(
      deployPortalFixture
    );
    expect(await fileversePortal.updateMetadata(ipfsHash))
      .to.emit(fileversePortal, "UpdatedPortalMetadata")
      .withArgs(ipfsHash, owner.address);
  });

  it("should be able to add file", async function () {
    const { fileversePortal, ipfsHash, owner } = await loadFixture(
      deployPortalFixture
    );
    expect(await fileversePortal.addFile(ipfsHash, ipfsHash, ipfsHash, 1, 0))
      .to.emit(fileversePortal, "AddedFile")
      .withArgs(0, ipfsHash, ipfsHash, ipfsHash, owner.address);
    expect(await fileversePortal.getFileCount()).to.equal(1);
  });

  it("should be able to edit file", async function () {
    const { fileversePortal, ipfsHash, owner } = await loadFixture(
      deployPortalFixture
    );
    expect(await fileversePortal.addFile(ipfsHash, ipfsHash, ipfsHash, 1, 0))
      .to.emit(fileversePortal, "AddedFile")
      .withArgs(0, ipfsHash, ipfsHash, ipfsHash, owner.address);
    expect(await fileversePortal.getFileCount()).to.equal(1);
    expect(
      await fileversePortal.editFile(0, ipfsHash, ipfsHash, ipfsHash, 1, 0)
    )
      .to.emit(fileversePortal, "EditedFile")
      .withArgs(0, ipfsHash, ipfsHash, ipfsHash, owner.address);
  });
});

describe("Fileverse Portal: Collaborator", function () {
  async function deployPortalFixtureCollaborator() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const FileversePortal = await ethers.getContractFactory("FileversePortal");
    const metadataIPFSHash = "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp5";
    const ownerViewDid =
      "did:key:z6MkkiKsFrxyb6mDd6RaWjDuuBs84T8vFtPgCds7jEC9bPbo";
    const ownerEditDid =
      "did:key:z6MkjeNxGFLaSrTTRnQbDcfXytYb8wAZiY1yy1X2g678xuYD";
    const addr1ViewDid =
      "did:key:z6MkkiKsFrxyb6mDd6RaWjDuuBs84T8vFtPgCds7jEC9bPbo";
    const addr1EditDid =
      "did:key:z6MkjeNxGFLaSrTTRnQbDcfXytYb8wAZiY1yy1X2g678xuYD";
    const keyVerifier = {
      portalEncryptionKeyVerifier:
        "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969",
      portalDecryptionKeyVerifier:
        "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969",
      memberEncryptionKeyVerifier:
        "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969",
      memberDecryptionKeyVerifier:
        "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969",
    };

    const trustedForwarder = "0x7EF22F49a2aE4a2E7c20369E6F7E5C9f94238141";

    const fileversePortal = await FileversePortal.deploy(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid,
      owner.address,
      trustedForwarder,
      keyVerifier
    );
    await fileversePortal.deployed();
    await fileversePortal.addCollaborator(addr1.address);
    // Fixtures can return anything you consider useful for your tests
    return {
      fileversePortal,
      FileversePortal,
      trustedForwarder,
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid,
      addr1ViewDid,
      addr1EditDid,
      owner,
      addr1,
      addr2,
      AddressOne: "0x0000000000000000000000000000000000000001",
      ipfsHash: "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp6",
    };
  }

  it("should be able to register self as member", async function () {
    const { fileversePortal, addr1EditDid, addr1ViewDid, addr1 } =
      await loadFixture(deployPortalFixtureCollaborator);
    await expect(
      fileversePortal
        .connect(addr1)
        .registerSelfToMember(addr1ViewDid, addr1EditDid)
    )
      .to.emit(fileversePortal, "RegisteredMember")
      .withArgs(addr1.address);
    expect(await fileversePortal.getMemberCount()).to.equal(2);
  });

  it("should be able to register and remove self as member", async function () {
    const { fileversePortal, addr1EditDid, addr1ViewDid, addr1 } =
      await loadFixture(deployPortalFixtureCollaborator);
    await expect(
      fileversePortal
        .connect(addr1)
        .registerSelfToMember(addr1ViewDid, addr1EditDid)
    )
      .to.emit(fileversePortal, "RegisteredMember")
      .withArgs(addr1.address);
    expect(await fileversePortal.getMemberCount()).to.equal(2);
    await expect(fileversePortal.connect(addr1).removeSelfFromMember())
      .to.emit(fileversePortal, "RemovedMember")
      .withArgs(addr1.address);
    expect(await fileversePortal.getMemberCount()).to.equal(1);
  });

  it("should be able to add file", async function () {
    const { fileversePortal, ipfsHash, addr1 } = await loadFixture(
      deployPortalFixtureCollaborator
    );
    expect(
      await fileversePortal
        .connect(addr1)
        .addFile(ipfsHash, ipfsHash, ipfsHash, 1, 0)
    )
      .to.emit(fileversePortal, "AddedFile")
      .withArgs(0, ipfsHash, ipfsHash, ipfsHash, addr1.address);
    expect(await fileversePortal.getFileCount()).to.equal(1);
  });

  it("should be able to edit file", async function () {
    const { fileversePortal, ipfsHash, addr1 } = await loadFixture(
      deployPortalFixtureCollaborator
    );
    expect(
      await fileversePortal
        .connect(addr1)
        .addFile(ipfsHash, ipfsHash, ipfsHash, 1, 0)
    )
      .to.emit(fileversePortal, "AddedFile")
      .withArgs(0, ipfsHash, ipfsHash, ipfsHash, addr1.address);
    expect(await fileversePortal.getFileCount()).to.equal(1);
    expect(
      await fileversePortal
        .connect(addr1)
        .editFile(0, ipfsHash, ipfsHash, ipfsHash, 1, 0)
    )
      .to.emit(fileversePortal, "EditedFile")
      .withArgs(0, ipfsHash, ipfsHash, ipfsHash, addr1.address);
  });
});
