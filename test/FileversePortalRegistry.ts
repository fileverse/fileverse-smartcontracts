import { expect } from "chai";
import { ethers } from "hardhat";
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Fileverse Portal Registry", function () {
  async function deployPortalRegistryFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const FileversePortalRegistry = await ethers.getContractFactory(
      "FileversePortalRegistry"
    );
    const trustedForwarder = "0x7EF22F49a2aE4a2E7c20369E6F7E5C9f94238141";
    const fileversePortalRegistry = await FileversePortalRegistry.deploy(
      trustedForwarder
    );
    await fileversePortalRegistry.deployed();
    // Fixtures can return anything you consider useful for your tests
    return {
      FileversePortalRegistry,
      fileversePortalRegistry,
      trustedForwarder,
      owner,
      addr1,
      addr2,
    };
  }

  it("should be able to deploy with correct number of parameters", async function () {
    const { fileversePortalRegistry } = await loadFixture(
      deployPortalRegistryFixture
    );
    expect(await fileversePortalRegistry.name()).to.equal(
      "Fileverse Portal Registry"
    );
  });

  it("should be able to deploy with correct empty state", async function () {
    const { fileversePortalRegistry, owner } = await loadFixture(
      deployPortalRegistryFixture
    );

    expect(await fileversePortalRegistry.name()).to.equal(
      "Fileverse Portal Registry"
    );
    const totalBalance = await fileversePortalRegistry.balancesOf(
      owner.address
    );
    expect(totalBalance).to.equal(0);
    const ownedPortals = await fileversePortalRegistry.ownedPortal(
      owner.address,
      10,
      1
    );
    expect(ownedPortals.length).to.equal(0);
    const allPortals = await fileversePortalRegistry.allPortal(10, 1);
    expect(allPortals.length).to.equal(0);
  });

  it("should have the same trusted forwarder", async function () {
    const { fileversePortalRegistry, trustedForwarder } = await loadFixture(
      deployPortalRegistryFixture
    );

    expect(await fileversePortalRegistry.name()).to.equal(
      "Fileverse Portal Registry"
    );
    expect(
      await fileversePortalRegistry.isTrustedForwarder(trustedForwarder)
    ).to.equal(true);
  });

  it("should be able to mint a fileverse portal with proper parameters", async function () {
    const { fileversePortalRegistry, owner } = await loadFixture(
      deployPortalRegistryFixture
    );
    const metadataIPFSHash = "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp5";
    const ownerViewDid =
      "did:key:z6MkkiKsFrxyb6mDd6RaWjDuuBs84T8vFtPgCds7jEC9bPbo";
    const ownerEditDid =
      "did:key:z6MkjeNxGFLaSrTTRnQbDcfXytYb8wAZiY1yy1X2g678xuYD";
    const keyVerifierHash =
      "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969";

    await fileversePortalRegistry.mint(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid,
      keyVerifierHash,
      keyVerifierHash,
      keyVerifierHash,
      keyVerifierHash
    );

    expect(await fileversePortalRegistry.balancesOf(owner.address)).to.equal(1);
    const ownedPortals = await fileversePortalRegistry.ownedPortal(
      owner.address,
      10,
      1
    );
    expect(ownedPortals.length).to.equal(1);
    const allPortals = await fileversePortalRegistry.allPortal(10, 1);
    expect(allPortals.length).to.equal(1);
  });

  it("should not be able to mint a fileverse portal with improper parameters", async function () {
    const { fileversePortalRegistry } = await loadFixture(
      deployPortalRegistryFixture
    );
    const metadataIPFSHash = "";
    const ownerViewDid = "";
    const ownerEditDid = "";
    const keyVerifierHash =
      "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969";

    await expect(
      fileversePortalRegistry.mint(
        metadataIPFSHash,
        ownerViewDid,
        ownerEditDid,
        keyVerifierHash,
        keyVerifierHash,
        keyVerifierHash,
        keyVerifierHash
      )
    ).to.revertedWith("FV201");
  });

  it("should be able to fire a mint event on creating a fileverse portal", async function () {
    const { fileversePortalRegistry, owner } = await loadFixture(
      deployPortalRegistryFixture
    );
    const metadataIPFSHash = "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp5";
    const ownerViewDid =
      "did:key:z6MkkiKsFrxyb6mDd6RaWjDuuBs84T8vFtPgCds7jEC9bPbo";
    const ownerEditDid =
      "did:key:z6MkjeNxGFLaSrTTRnQbDcfXytYb8wAZiY1yy1X2g678xuYD";
    const keyVerifierHash =
      "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969";

    await fileversePortalRegistry.mint(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid,
      keyVerifierHash,
      keyVerifierHash,
      keyVerifierHash,
      keyVerifierHash
    );
    await fileversePortalRegistry.mint(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid,
      keyVerifierHash,
      keyVerifierHash,
      keyVerifierHash,
      keyVerifierHash
    );

    expect(await fileversePortalRegistry.balancesOf(owner.address)).to.equal(2);
    const ownedPortals = await fileversePortalRegistry.ownedPortal(
      owner.address,
      10,
      1
    );
    expect(ownedPortals.length).to.equal(2);
    const allPortals = await fileversePortalRegistry.allPortal(10, 1);
    expect(allPortals.length).to.equal(2);
  });

  it("should be able to create two fileverse portal", async function () {
    const { fileversePortalRegistry, owner } = await loadFixture(
      deployPortalRegistryFixture
    );
    const metadataIPFSHash = "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp5";
    const ownerViewDid =
      "did:key:z6MkkiKsFrxyb6mDd6RaWjDuuBs84T8vFtPgCds7jEC9bPbo";
    const ownerEditDid =
      "did:key:z6MkjeNxGFLaSrTTRnQbDcfXytYb8wAZiY1yy1X2g678xuYD";
    const keyVerifierHash =
      "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969";

    await expect(
      fileversePortalRegistry.mint(
        metadataIPFSHash,
        ownerViewDid,
        ownerEditDid,
        keyVerifierHash,
        keyVerifierHash,
        keyVerifierHash,
        keyVerifierHash
      )
    ).to.emit(fileversePortalRegistry, "Mint");
    await expect(
      fileversePortalRegistry.mint(
        metadataIPFSHash,
        ownerViewDid,
        ownerEditDid,
        keyVerifierHash,
        keyVerifierHash,
        keyVerifierHash,
        keyVerifierHash
      )
    ).to.emit(fileversePortalRegistry, "Mint");

    expect(await fileversePortalRegistry.balancesOf(owner.address)).to.equal(2);
    const ownedPortals = await fileversePortalRegistry.ownedPortal(
      owner.address,
      10,
      1
    );
    expect(ownedPortals.length).to.equal(2);
    const allPortals = await fileversePortalRegistry.allPortal(10, 1);
    expect(allPortals.length).to.equal(2);
  });

  it("should be able to create two fileverse portal by two addresses", async function () {
    const { fileversePortalRegistry, owner, addr1 } = await loadFixture(
      deployPortalRegistryFixture
    );
    const metadataIPFSHash = "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp5";
    const ownerViewDid =
      "did:key:z6MkkiKsFrxyb6mDd6RaWjDuuBs84T8vFtPgCds7jEC9bPbo";
    const ownerEditDid =
      "did:key:z6MkjeNxGFLaSrTTRnQbDcfXytYb8wAZiY1yy1X2g678xuYD";
    const keyVerifierHash =
      "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969";

    await expect(
      fileversePortalRegistry.mint(
        metadataIPFSHash,
        ownerViewDid,
        ownerEditDid,
        keyVerifierHash,
        keyVerifierHash,
        keyVerifierHash,
        keyVerifierHash
      )
    ).to.emit(fileversePortalRegistry, "Mint");

    expect(await fileversePortalRegistry.balancesOf(owner.address)).to.equal(1);
    const ownedPortals = await fileversePortalRegistry.ownedPortal(
      owner.address,
      10,
      1
    );
    expect(ownedPortals.length).to.equal(1);

    await expect(
      fileversePortalRegistry
        .connect(addr1)
        .mint(
          metadataIPFSHash,
          ownerViewDid,
          ownerEditDid,
          keyVerifierHash,
          keyVerifierHash,
          keyVerifierHash,
          keyVerifierHash
        )
    ).to.emit(fileversePortalRegistry, "Mint");
    expect(
      await fileversePortalRegistry.connect(addr1).balancesOf(addr1.address)
    ).to.equal(1);
    const ownedPortalsAddr1 = await fileversePortalRegistry.ownedPortal(
      owner.address,
      10,
      1
    );
    expect(ownedPortalsAddr1.length).to.equal(1);

    const allPortals = await fileversePortalRegistry.allPortal(10, 1);
    expect(allPortals.length).to.equal(2);
  });

  it("should have the sender of the txn as owner", async function () {
    const { fileversePortalRegistry, owner } = await loadFixture(
      deployPortalRegistryFixture
    );
    const metadataIPFSHash = "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp5";
    const ownerViewDid =
      "did:key:z6MkkiKsFrxyb6mDd6RaWjDuuBs84T8vFtPgCds7jEC9bPbo";
    const ownerEditDid =
      "did:key:z6MkjeNxGFLaSrTTRnQbDcfXytYb8wAZiY1yy1X2g678xuYD";
    const keyVerifierHash =
      "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969";

    const data = await fileversePortalRegistry.mint(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid,
      keyVerifierHash,
      keyVerifierHash,
      keyVerifierHash,
      keyVerifierHash
    );
    const txReciept = await data.wait();
    const mintEvent = txReciept.events.find((elem) => elem.event === "Mint");
    const { portal } = mintEvent.args;
    expect(await fileversePortalRegistry.balancesOf(owner.address)).to.equal(1);
    const ownedPortals = await fileversePortalRegistry.ownedPortal(
      owner.address,
      10,
      1
    );
    expect(ownedPortals.length).to.equal(1);
    expect(ownedPortals[0].portal).to.equal(portal);
    const allPortals = await fileversePortalRegistry.allPortal(10, 1);
    expect(allPortals.length).to.equal(1);
  });

  it("should have functional getter functions as owner", async function () {
    const { fileversePortalRegistry, owner } = await loadFixture(
      deployPortalRegistryFixture
    );
    const metadataIPFSHash = "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp5";
    const ownerViewDid =
      "did:key:z6MkkiKsFrxyb6mDd6RaWjDuuBs84T8vFtPgCds7jEC9bPbo";
    const ownerEditDid =
      "did:key:z6MkjeNxGFLaSrTTRnQbDcfXytYb8wAZiY1yy1X2g678xuYD";
    const keyVerifierHash =
      "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969";

    const data = await fileversePortalRegistry.mint(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid,
      keyVerifierHash,
      keyVerifierHash,
      keyVerifierHash,
      keyVerifierHash
    );
    const txReciept = await data.wait();
    const mintEvent = txReciept.events.find((elem) => elem.event === "Mint");
    const { portal } = mintEvent.args;
    expect(await fileversePortalRegistry.balancesOf(owner.address)).to.equal(1);

    expect(await fileversePortalRegistry.ownerOf(portal)).to.equal(
      owner.address
    );
    const portalInfo = await fileversePortalRegistry.portalInfo(portal);
    expect(portalInfo.index).to.equal(0);
    expect(portalInfo.tokenId).to.equal(0);
    expect(portalInfo.portal).to.equal(portal);
  });

  it("should have functional getter functions as reader", async function () {
    const { fileversePortalRegistry, owner, addr1 } = await loadFixture(
      deployPortalRegistryFixture
    );
    const metadataIPFSHash = "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp5";
    const ownerViewDid =
      "did:key:z6MkkiKsFrxyb6mDd6RaWjDuuBs84T8vFtPgCds7jEC9bPbo";
    const ownerEditDid =
      "did:key:z6MkjeNxGFLaSrTTRnQbDcfXytYb8wAZiY1yy1X2g678xuYD";
    const keyVerifierHash =
      "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969";

    const data = await fileversePortalRegistry.mint(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid,
      keyVerifierHash,
      keyVerifierHash,
      keyVerifierHash,
      keyVerifierHash
    );
    const txReciept = await data.wait();
    const mintEvent = txReciept.events.find((elem) => elem.event === "Mint");
    const { portal } = mintEvent.args;
    expect(await fileversePortalRegistry.balancesOf(owner.address)).to.equal(1);
    expect(
      await fileversePortalRegistry.connect(addr1).ownerOf(portal)
    ).to.equal(owner.address);
    const portalInfo = await fileversePortalRegistry
      .connect(addr1)
      .portalInfo(portal);
    expect(portalInfo.index).to.equal(0);
    expect(portalInfo.tokenId).to.equal(0);
    expect(portalInfo.portal).to.equal(portal);
  });
});

describe("Fileverse Portal Registry: Deployed Portal", function () {
  async function deployPortalRegistryFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const FileversePortalRegistry = await ethers.getContractFactory(
      "FileversePortalRegistry"
    );
    const trustedForwarder = "0x7EF22F49a2aE4a2E7c20369E6F7E5C9f94238141";
    const fileversePortalRegistry = await FileversePortalRegistry.deploy(
      trustedForwarder
    );
    await fileversePortalRegistry.deployed();
    const metadataIPFSHash = "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp5";
    const ownerViewDid =
      "did:key:z6MkkiKsFrxyb6mDd6RaWjDuuBs84T8vFtPgCds7jEC9bPbo";
    const ownerEditDid =
      "did:key:z6MkjeNxGFLaSrTTRnQbDcfXytYb8wAZiY1yy1X2g678xuYD";
    const keyVerifierHash =
      "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969";

    const data = await fileversePortalRegistry.mint(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid,
      keyVerifierHash,
      keyVerifierHash,
      keyVerifierHash,
      keyVerifierHash
    );
    const txReciept = await data.wait();
    const mintEvent = txReciept.events.find((elem) => elem.event === "Mint");
    const { portal } = mintEvent.args;
    const FileversePortal = await ethers.getContractFactory("FileversePortal");
    const deployedFileversePortal = await FileversePortal.attach(portal);
    // Fixtures can return anything you consider useful for your tests
    return {
      portal,
      FileversePortal,
      deployedFileversePortal,
      FileversePortalRegistry,
      fileversePortalRegistry,
      trustedForwarder,
      keyVerifierHash,
      owner,
      addr1,
      addr2,
    };
  }

  it("should be able to deploy with correct initial state", async function () {
    const { deployedFileversePortal, trustedForwarder, owner } =
      await loadFixture(deployPortalRegistryFixture);
    expect(
      await deployedFileversePortal.isTrustedForwarder(trustedForwarder)
    ).to.equal(true);
    expect(await deployedFileversePortal.owner()).to.equal(owner.address);
    expect(await deployedFileversePortal.getCollaboratorCount()).to.equal(1);
    expect(await deployedFileversePortal.getMemberCount()).to.equal(1);
    expect(await deployedFileversePortal.getFileCount()).to.equal(0);
  });

  it("should be able to deploy with correct key verifiers", async function () {
    const { deployedFileversePortal, keyVerifierHash } = await loadFixture(
      deployPortalRegistryFixture
    );
    const newHash =
      "0x948edbe7ede5aa7423476ae29dcd7d61e7711a071aea0d83698377effa896525";
    await expect(
      deployedFileversePortal.updateKeyVerifiers(
        newHash,
        newHash,
        newHash,
        newHash
      )
    ).to.emit(deployedFileversePortal, "UpdatedKeyVerifiers");
    const keyVerifiers = await deployedFileversePortal.keyVerifiers(0);
    expect(keyVerifiers.portalEncryptionKeyVerifier).to.equal(keyVerifierHash);
    expect(keyVerifiers.portalDecryptionKeyVerifier).to.equal(keyVerifierHash);
    expect(keyVerifiers.memberEncryptionKeyVerifier).to.equal(keyVerifierHash);
    expect(keyVerifiers.memberDecryptionKeyVerifier).to.equal(keyVerifierHash);
  });

  it("should be able to update the key verifiers of the deployed portal", async function () {
    const { deployedFileversePortal, keyVerifierHash } = await loadFixture(
      deployPortalRegistryFixture
    );
    const keyVerifiersInitial = await deployedFileversePortal.keyVerifiers(0);
    expect(keyVerifiersInitial.portalEncryptionKeyVerifier).to.equal(
      keyVerifierHash
    );
    expect(keyVerifiersInitial.portalDecryptionKeyVerifier).to.equal(
      keyVerifierHash
    );
    expect(keyVerifiersInitial.memberEncryptionKeyVerifier).to.equal(
      keyVerifierHash
    );
    expect(keyVerifiersInitial.memberDecryptionKeyVerifier).to.equal(
      keyVerifierHash
    );
    const newHash =
      "0x948edbe7ede5aa7423476ae29dcd7d61e7711a071aea0d83698377effa896525";
    await deployedFileversePortal.updateKeyVerifiers(
      newHash,
      newHash,
      newHash,
      newHash
    );
    const keyVerifiersNew = await deployedFileversePortal.keyVerifiers(1);
    expect(keyVerifiersNew.portalEncryptionKeyVerifier).to.equal(newHash);
    expect(keyVerifiersNew.portalDecryptionKeyVerifier).to.equal(newHash);
    expect(keyVerifiersNew.memberEncryptionKeyVerifier).to.equal(newHash);
    expect(keyVerifiersNew.memberDecryptionKeyVerifier).to.equal(newHash);
  });

  it("should be able to deploy with correct collaborator set", async function () {
    const { deployedFileversePortal, owner } = await loadFixture(
      deployPortalRegistryFixture
    );
    expect(
      await deployedFileversePortal.isCollaborator(owner.address)
    ).to.equal(true);
  });
});
