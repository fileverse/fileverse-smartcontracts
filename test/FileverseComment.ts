import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("FileverseComment", () => {
  let comment: any;
  let portal: any;
  let registry: any;
  let owner: SignerWithAddress;
  let user: SignerWithAddress;
  let forwarder: SignerWithAddress;

  const fileId = "test-file-1";
  const contentHash = "QmTest123";
  const metadataHash = "QmPortalMetadata";
  const ownerViewDid = "did:key:owner-view";
  const ownerEditDid = "did:key:owner-edit";
  const keyVerifier = ethers.utils.formatBytes32String("test-key");

  beforeEach(async () => {
    [owner, user, forwarder] = await ethers.getSigners();

    const FileverseComment = await ethers.getContractFactory(
      "FileverseComment"
    );
    comment = await FileverseComment.deploy(forwarder.address);
    await comment.deployed();

    const FileversePortalRegistry = await ethers.getContractFactory(
      "FileversePortalRegistry"
    );
    registry = await FileversePortalRegistry.deploy(forwarder.address);
    await registry.deployed();

    await registry.mint(
      metadataHash,
      ownerViewDid,
      ownerEditDid,
      keyVerifier,
      keyVerifier,
      keyVerifier,
      keyVerifier
    );

    const portalAddress = (await registry.allPortal(1, 1))[0].portal;
    portal = await ethers.getContractAt("FileversePortal", portalAddress);
  });

  describe("addComment", () => {
    it("should add a new comment", async () => {
      await comment.addComment(portal.address, fileId, contentHash);
      const comments = await comment.getComments(portal.address, fileId, 10, 1);
      expect(comments.length).to.equal(1);
      expect(comments[0].author).to.equal(owner.address);
      expect(comments[0].contentHash).to.equal(contentHash);
      expect(comments[0].isResolved).to.equal(false);
      expect(comments[0].isDeleted).to.equal(false);
    });

    it("should revert with invalid portal address", async () => {
      await expect(
        comment.addComment(ethers.constants.AddressZero, fileId, contentHash)
      ).to.be.revertedWith("Invalid portal address");
    });
  });

  describe("resolveComment", () => {
    beforeEach(async () => {
      await comment.addComment(portal.address, fileId, contentHash);
    });

    it("should resolve a comment", async () => {
      await comment.resolveComment(portal.address, fileId, 0);
      const comments = await comment.getComments(portal.address, fileId, 10, 1);
      expect(comments[0].isResolved).to.equal(true);
    });

    it("should revert if caller is not portal owner", async () => {
      await expect(
        comment.connect(user).resolveComment(portal.address, fileId, 0)
      ).to.be.revertedWith("Only portal owner can resolve comments");
    });
  });

  describe("deleteComment", () => {
    beforeEach(async () => {
      await comment.addComment(portal.address, fileId, contentHash);
    });

    it("should delete a comment", async () => {
      await comment.deleteComment(portal.address, fileId, 0);
      const comments = await comment.getComments(portal.address, fileId, 10, 1);
      expect(comments[0].isDeleted).to.equal(true);
    });

    it("should revert if caller is not portal owner", async () => {
      await expect(
        comment.connect(user).deleteComment(portal.address, fileId, 0)
      ).to.be.revertedWith("Only portal owner can delete comments");
    });
  });

  describe("getComments", () => {
    beforeEach(async () => {
      // Add multiple comments
      for (let i = 0; i < 5; i++) {
        await comment.addComment(portal.address, fileId, `${contentHash}-${i}`);
      }
    });

    it("should return paginated comments", async () => {
      const comments = await comment.getComments(portal.address, fileId, 2, 1);
      expect(comments.length).to.equal(2);
    });

    it("should revert with invalid page", async () => {
      await expect(
        comment.getComments(portal.address, fileId, 10, 100)
      ).to.be.revertedWith("Page out of bounds");
    });
  });

  describe("getCommentCount", () => {
    it("should return correct comment count", async () => {
      await comment.addComment(portal.address, fileId, contentHash);
      await comment.addComment(portal.address, fileId, `${contentHash}-2`);

      const count = await comment.getCommentCount(portal.address, fileId);
      expect(count).to.equal(2);
    });
  });
});
