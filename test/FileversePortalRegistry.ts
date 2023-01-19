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
    const { fileversePortalRegistry } = await loadFixture(deployPortalRegistryFixture);
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
    expect(await fileversePortalRegistry.balancesOf(owner.address)).to.equal(0);
    const ownedPortals = await fileversePortalRegistry.ownedPortal(
      owner.address
    );
    expect(ownedPortals.length).to.equal(0);
    const allPortals = await fileversePortalRegistry.allPortal();
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

  it("should be able to mint a fileverse portal", async function () {
    const { fileversePortalRegistry, owner } = await loadFixture(
      deployPortalRegistryFixture
    );
    const metadataIPFSHash = "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp5";
    const ownerViewDid =
      "did:key:z6MkkiKsFrxyb6mDd6RaWjDuuBs84T8vFtPgCds7jEC9bPbo";
    const ownerEditDid =
      "did:key:z6MkjeNxGFLaSrTTRnQbDcfXytYb8wAZiY1yy1X2g678xuYD";

    await fileversePortalRegistry.mint(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid
    );

    expect(await fileversePortalRegistry.balancesOf(owner.address)).to.equal(1);
    const ownedPortals = await fileversePortalRegistry.ownedPortal(
      owner.address
    );
    expect(ownedPortals.length).to.equal(1);
    const allPortals = await fileversePortalRegistry.allPortal();
    expect(allPortals.length).to.equal(1);
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

    await fileversePortalRegistry.mint(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid
    );
    await fileversePortalRegistry.mint(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid
    );

    expect(await fileversePortalRegistry.balancesOf(owner.address)).to.equal(2);
    const ownedPortals = await fileversePortalRegistry.ownedPortal(
      owner.address
    );
    expect(ownedPortals.length).to.equal(2);
    const allPortals = await fileversePortalRegistry.allPortal();
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

    await expect(
      fileversePortalRegistry.mint(metadataIPFSHash, ownerViewDid, ownerEditDid)
    ).to.emit(fileversePortalRegistry, "Mint");
    await expect(
      fileversePortalRegistry.mint(metadataIPFSHash, ownerViewDid, ownerEditDid)
    ).to.emit(fileversePortalRegistry, "Mint");

    expect(await fileversePortalRegistry.balancesOf(owner.address)).to.equal(2);
    const ownedPortals = await fileversePortalRegistry.ownedPortal(
      owner.address
    );
    expect(ownedPortals.length).to.equal(2);
    const allPortals = await fileversePortalRegistry.allPortal();
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

    await expect(
      fileversePortalRegistry.mint(metadataIPFSHash, ownerViewDid, ownerEditDid)
    ).to.emit(fileversePortalRegistry, "Mint");

    expect(await fileversePortalRegistry.balancesOf(owner.address)).to.equal(1);
    const ownedPortals = await fileversePortalRegistry.ownedPortal(
      owner.address
    );
    expect(ownedPortals.length).to.equal(1);

    await expect(
      fileversePortalRegistry
        .connect(addr1)
        .mint(metadataIPFSHash, ownerViewDid, ownerEditDid)
    ).to.emit(fileversePortalRegistry, "Mint");
    expect(
      await fileversePortalRegistry.connect(addr1).balancesOf(addr1.address)
    ).to.equal(1);
    const ownedPortalsAddr1 = await fileversePortalRegistry.ownedPortal(
      addr1.address
    );
    expect(ownedPortalsAddr1.length).to.equal(1);

    const allPortals = await fileversePortalRegistry.allPortal();
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

    const data = await fileversePortalRegistry.mint(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid
    );
    const txReciept = await data.wait();
    const mintEvent = txReciept.events.find((elem) => elem.event === "Mint");
    const { portal } = mintEvent.args;
    expect(await fileversePortalRegistry.balancesOf(owner.address)).to.equal(1);
    const ownedPortals = await fileversePortalRegistry.ownedPortal(
      owner.address
    );
    expect(ownedPortals.length).to.equal(1);
    expect(ownedPortals[0].portal).to.equal(portal);
    const allPortals = await fileversePortalRegistry.allPortal();
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

    const data = await fileversePortalRegistry.mint(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid
    );
    const txReciept = await data.wait();
    const mintEvent = txReciept.events.find((elem) => elem.event === "Mint");
    const { portal } = mintEvent.args;
    expect(await fileversePortalRegistry.balancesOf(owner.address)).to.equal(1);

    expect(await fileversePortalRegistry.ownerOf(portal)).to.equal(
      owner.address
    );
    const portalInfo = await fileversePortalRegistry.portalInfo(portal);
    expect(portalInfo.index).to.equal(1);
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

    const data = await fileversePortalRegistry.mint(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid
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
    expect(portalInfo.index).to.equal(1);
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

    const data = await fileversePortalRegistry.mint(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid
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
});
