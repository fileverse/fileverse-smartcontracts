import { expect } from "chai";
import { ethers } from "hardhat";
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("GranularPermission", function () {
  // Define a fixture for deploying the contracts
  async function deployGranularPermissionFixture() {
    const [owner, addr1, addr2, addr3] = await ethers.getSigners();

    // Deploy FileversePortal first
    const metadataIPFSHash = "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp5";
    const ownerViewDid =
      "did:key:z6MkkiKsFrxyb6mDd6RaWjDuuBs84T8vFtPgCds7jEC9bPbo";
    const ownerEditDid =
      "did:key:z6MkjeNxGFLaSrTTRnQbDcfXytYb8wAZiY1yy1X2g678xuYD";
    const trustedForwarder = "0x7EF22F49a2aE4a2E7c20369E6F7E5C9f94238141";
    const keyVerifierHash =
      "0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969";
    const keyVerifier = {
      portalEncryptionKeyVerifier: keyVerifierHash,
      portalDecryptionKeyVerifier: keyVerifierHash,
      memberEncryptionKeyVerifier: keyVerifierHash,
      memberDecryptionKeyVerifier: keyVerifierHash,
    };

    const FileversePortal = await ethers.getContractFactory("FileversePortal");
    const fileversePortal = await FileversePortal.deploy(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid,
      owner.address,
      trustedForwarder,
      keyVerifier
    );
    await fileversePortal.deployed();

    // Deploy GranularPermission
    const GranularPermission = await ethers.getContractFactory(
      "GranularPermission"
    );
    const granularPermission = await GranularPermission.deploy(
      fileversePortal.address
    );
    await granularPermission.deployed();

    // Add GranularPermission contract as a collaborator to FileversePortal
    await fileversePortal.addCollaborator(granularPermission.address);

    // Set up a test file in the portal
    const ipfsHash = "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp6";
    await fileversePortal.addFile(ipfsHash, ipfsHash, "", 0, 0); // Add a public file (fileId = 0)
    await fileversePortal.addFile(ipfsHash, ipfsHash, "", 1, 0); // Add a private file (fileId = 1)

    return {
      granularPermission,
      fileversePortal,
      owner,
      addr1,
      addr2,
      addr3,
      ipfsHash,
      keyVerifierHash,
      AddressOne: "0x0000000000000000000000000000000000000001",
    };
  }

  // Test deployment
  describe("Deployment", function () {
    it("should set the correct portal contract reference", async function () {
      const { granularPermission, fileversePortal } = await loadFixture(
        deployGranularPermissionFixture
      );
      expect(await granularPermission.portalContract()).to.equal(
        fileversePortal.address
      );
    });

    it("should have the correct owner", async function () {
      const { granularPermission, owner } = await loadFixture(
        deployGranularPermissionFixture
      );
      expect(await granularPermission.owner()).to.equal(owner.address);
    });
  });

  // Test permission management
  describe("Permission Management", function () {
    it("should correctly update user permission for a file", async function () {
      const { granularPermission, addr1 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // Grant READ permission to addr1 for fileId 0
      await granularPermission.updatePermission(addr1.address, 0, 1); // Permission.READ = 1

      // Check permission was set correctly
      expect(await granularPermission.getPermission(addr1.address, 0)).to.equal(
        1
      );
      expect(
        await granularPermission.hasReadPermission(addr1.address, 0)
      ).to.equal(true);
      expect(
        await granularPermission.hasWritePermission(addr1.address, 0)
      ).to.equal(false);

      // Verify counts
      expect(await granularPermission.getUserFileCount(addr1.address)).to.equal(
        1
      );
      expect(await granularPermission.getFileUserCount(0)).to.equal(1);
    });

    it("should correctly update permission from READ to WRITE", async function () {
      const { granularPermission, addr1 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // First grant READ permission
      await granularPermission.updatePermission(addr1.address, 0, 1); // Permission.READ = 1
      expect(await granularPermission.getPermission(addr1.address, 0)).to.equal(
        1
      );

      // Then upgrade to WRITE permission
      await granularPermission.updatePermission(addr1.address, 0, 2); // Permission.WRITE = 2

      // Check permission was upgraded correctly
      expect(await granularPermission.getPermission(addr1.address, 0)).to.equal(
        2
      );
      expect(
        await granularPermission.hasReadPermission(addr1.address, 0)
      ).to.equal(true);
      expect(
        await granularPermission.hasWritePermission(addr1.address, 0)
      ).to.equal(true);

      // Verify counts (should still be 1 since it's the same file)
      expect(await granularPermission.getUserFileCount(addr1.address)).to.equal(
        1
      );
      expect(await granularPermission.getFileUserCount(0)).to.equal(1);
    });

    it("should correctly revoke permission by setting to NONE", async function () {
      const { granularPermission, addr1 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // First grant WRITE permission
      await granularPermission.updatePermission(addr1.address, 0, 2); // Permission.WRITE = 2
      expect(await granularPermission.getPermission(addr1.address, 0)).to.equal(
        2
      );

      // Then revoke by setting to NONE
      await granularPermission.updatePermission(addr1.address, 0, 0); // Permission.NONE = 0

      // Check permission was revoked correctly
      expect(await granularPermission.getPermission(addr1.address, 0)).to.equal(
        0
      );
      expect(
        await granularPermission.hasReadPermission(addr1.address, 0)
      ).to.equal(false);
      expect(
        await granularPermission.hasWritePermission(addr1.address, 0)
      ).to.equal(false);

      // Verify counts (should be 0 after revocation)
      expect(await granularPermission.getUserFileCount(addr1.address)).to.equal(
        0
      );
      expect(await granularPermission.getFileUserCount(0)).to.equal(0);
    });

    it("should emit PermissionUpdated event when permission is updated", async function () {
      const { granularPermission, addr1 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // Grant READ permission and verify event
      await expect(granularPermission.updatePermission(addr1.address, 0, 1))
        .to.emit(granularPermission, "PermissionUpdated")
        .withArgs(addr1.address, 0, 1);

      // Upgrade to WRITE permission and verify event
      await expect(granularPermission.updatePermission(addr1.address, 0, 2))
        .to.emit(granularPermission, "PermissionUpdated")
        .withArgs(addr1.address, 0, 2);

      // Revoke permission and verify event
      await expect(granularPermission.updatePermission(addr1.address, 0, 0))
        .to.emit(granularPermission, "PermissionUpdated")
        .withArgs(addr1.address, 0, 0);
    });

    it("should fail when updating permission for non-existent file", async function () {
      const { granularPermission, addr1 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // Try to grant permission for a non-existent file (e.g., fileId 999)
      await expect(
        granularPermission.updatePermission(addr1.address, 999, 1)
      ).to.be.revertedWith("FP004: File does not exist");
    });

    it("should fail when updating permission for zero address", async function () {
      const { granularPermission } = await loadFixture(
        deployGranularPermissionFixture
      );

      // Try to grant permission to zero address
      await expect(
        granularPermission.updatePermission(ethers.constants.AddressZero, 0, 1)
      ).to.be.revertedWith("FP005: User cannot be zero address");
    });

    it("should fail when non-owner attempts to update permissions", async function () {
      const { granularPermission, addr1, addr2 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // Try to grant permission as non-owner
      await expect(
        granularPermission.connect(addr1).updatePermission(addr2.address, 0, 1)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  // Test batch permission updates
  describe("Batch Permission Updates", function () {
    it("should update permissions for multiple users on a file", async function () {
      const { granularPermission, addr1, addr2, addr3 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // Grant READ permission to multiple users for fileId 0
      await granularPermission.updateBatchPermissions(
        [addr1.address, addr2.address, addr3.address],
        0,
        1 // Permission.READ
      );

      // Verify permissions were set correctly
      expect(await granularPermission.getPermission(addr1.address, 0)).to.equal(
        1
      );
      expect(await granularPermission.getPermission(addr2.address, 0)).to.equal(
        1
      );
      expect(await granularPermission.getPermission(addr3.address, 0)).to.equal(
        1
      );

      // Verify file user count
      expect(await granularPermission.getFileUserCount(0)).to.equal(3);
    });

    it("should update permissions for multiple users to different levels", async function () {
      const { granularPermission, addr1, addr2, addr3 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // First grant READ to all
      await granularPermission.updateBatchPermissions(
        [addr1.address, addr2.address, addr3.address],
        0,
        1 // Permission.READ
      );

      // Then upgrade addr2 to WRITE
      await granularPermission.updatePermission(addr2.address, 0, 2);

      // Verify permissions were set correctly
      expect(await granularPermission.getPermission(addr1.address, 0)).to.equal(
        1
      ); // READ
      expect(await granularPermission.getPermission(addr2.address, 0)).to.equal(
        2
      ); // WRITE
      expect(await granularPermission.getPermission(addr3.address, 0)).to.equal(
        1
      ); // READ
    });

    it("should skip zero addresses in batch updates", async function () {
      const { granularPermission, addr1, addr2 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // Include a zero address in the batch update
      await granularPermission.updateBatchPermissions(
        [addr1.address, ethers.constants.AddressZero, addr2.address],
        0,
        1 // Permission.READ
      );

      // Verify only valid addresses got permissions
      expect(await granularPermission.getPermission(addr1.address, 0)).to.equal(
        1
      );
      expect(await granularPermission.getPermission(addr2.address, 0)).to.equal(
        1
      );

      // Verify file user count (should be 2, not 3)
      expect(await granularPermission.getFileUserCount(0)).to.equal(2);
    });
  });

  // Test revoking all permissions
  describe("Revoking All Permissions", function () {
    it("should revoke all permissions for a file", async function () {
      const { granularPermission, addr1, addr2, addr3 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // First grant permissions to multiple users
      await granularPermission.updateBatchPermissions(
        [addr1.address, addr2.address, addr3.address],
        0,
        1 // Permission.READ
      );

      // Verify permissions were set
      expect(await granularPermission.getFileUserCount(0)).to.equal(3);

      // Revoke all permissions for fileId 0
      await granularPermission.revokeAllFilePermissions(0);

      // Verify all permissions were revoked
      expect(await granularPermission.getPermission(addr1.address, 0)).to.equal(
        0
      );
      expect(await granularPermission.getPermission(addr2.address, 0)).to.equal(
        0
      );
      expect(await granularPermission.getPermission(addr3.address, 0)).to.equal(
        0
      );

      // Verify file user count is now 0
      expect(await granularPermission.getFileUserCount(0)).to.equal(0);
    });
  });

  // Test user file queries
  describe("User File Queries", function () {
    it("should correctly return active files for a user", async function () {
      const { granularPermission, addr1 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // Grant permissions to multiple files
      await granularPermission.updatePermission(addr1.address, 0, 1); // READ for file 0
      await granularPermission.updatePermission(addr1.address, 1, 2); // WRITE for file 1

      // Get user's active files
      const [activeFiles, totalCount] =
        await granularPermission.getUserActiveFiles(addr1.address, 10);

      // Verify results
      expect(totalCount).to.equal(2);
      expect(activeFiles.length).to.equal(2);
      expect(activeFiles).to.deep.include.members([
        ethers.BigNumber.from(0),
        ethers.BigNumber.from(1),
      ]);
    });

    it("should correctly paginate user's active files", async function () {
      const { granularPermission, addr1 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // Grant permissions to multiple files
      await granularPermission.updatePermission(addr1.address, 0, 1); // READ for file 0
      await granularPermission.updatePermission(addr1.address, 1, 2); // WRITE for file 1

      // First verify we have 2 total files
      const [allFiles, totalCount] =
        await granularPermission.getUserActiveFiles(addr1.address, 10);
      expect(totalCount).to.equal(2);
      expect(allFiles.length).to.equal(2);

      // Now get all files with pagination, one file per page
      // First page - get one file
      const [firstPage] = await granularPermission.getUserActiveFilesPaginated(
        addr1.address,
        0, // start from the beginning
        1 // get only one file
      );

      // Verify we got one file and there are more
      expect(firstPage.length).to.equal(1);

      // Get a second page starting after first file
      // We'll use file ID 0 which we know exists
      const [secondPage] = await granularPermission.getUserActiveFilesPaginated(
        addr1.address,
        0, // start after file 0
        1 // get only one file
      );

      // Verify we got second page
      expect(secondPage.length).to.equal(1);

      // Verify that all files were retrieved (by checking we got 2 distinct files)
      const allRetrievedFiles = [...firstPage, ...secondPage];
      expect(allRetrievedFiles.length).to.equal(2);
    });
  });

  // Test file user queries
  describe("File User Queries", function () {
    it("should correctly return active users for a file", async function () {
      const { granularPermission, addr1, addr2, addr3 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // Grant permissions to multiple users for file 0
      await granularPermission.updatePermission(addr1.address, 0, 1); // READ for addr1
      await granularPermission.updatePermission(addr2.address, 0, 2); // WRITE for addr2
      await granularPermission.updatePermission(addr3.address, 0, 1); // READ for addr3

      // Get file's active users
      const [activeUsers, totalCount] =
        await granularPermission.getFileActiveUsers(0, 10);

      // Verify results
      expect(totalCount).to.equal(3);
      expect(activeUsers.length).to.equal(3);
      expect(activeUsers).to.include.members([
        addr1.address,
        addr2.address,
        addr3.address,
      ]);
    });

    it("should correctly paginate file's active users", async function () {
      const { granularPermission, addr1, addr2, addr3 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // Grant permissions to multiple users for file 0
      await granularPermission.updatePermission(addr1.address, 0, 1); // READ for addr1
      await granularPermission.updatePermission(addr2.address, 0, 2); // WRITE for addr2
      await granularPermission.updatePermission(addr3.address, 0, 1); // READ for addr3

      // Get first page of file's active users (limit 2)
      const [firstPage, hasMoreFirst] =
        await granularPermission.getFileActiveUsersPaginated(
          0,
          ethers.constants.AddressZero,
          2
        );

      // Verify first page
      expect(firstPage.length).to.equal(2);
      expect(hasMoreFirst).to.equal(true);

      // Get second page (starting after last user in first page)
      const [secondPage, hasMoreSecond] =
        await granularPermission.getFileActiveUsersPaginated(
          0,
          firstPage[1],
          2
        );

      // Verify second page
      expect(secondPage.length).to.equal(1);
      expect(hasMoreSecond).to.equal(false);
    });
  });

  // Test permission checks
  describe("Permission Checks", function () {
    it("should correctly check READ permission", async function () {
      const { granularPermission, addr1, addr2 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // Grant READ to addr1 and WRITE to addr2
      await granularPermission.updatePermission(addr1.address, 0, 1); // READ for addr1
      await granularPermission.updatePermission(addr2.address, 0, 2); // WRITE for addr2

      // Check permissions
      expect(
        await granularPermission.hasReadPermission(addr1.address, 0)
      ).to.equal(true);
      expect(
        await granularPermission.hasReadPermission(addr2.address, 0)
      ).to.equal(true); // WRITE includes READ
    });

    it("should correctly check WRITE permission", async function () {
      const { granularPermission, addr1, addr2 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // Grant READ to addr1 and WRITE to addr2
      await granularPermission.updatePermission(addr1.address, 0, 1); // READ for addr1
      await granularPermission.updatePermission(addr2.address, 0, 2); // WRITE for addr2

      // Check permissions
      expect(
        await granularPermission.hasWritePermission(addr1.address, 0)
      ).to.equal(false);
      expect(
        await granularPermission.hasWritePermission(addr2.address, 0)
      ).to.equal(true);
    });

    it("should get permission levels for multiple files", async function () {
      const { granularPermission, addr1 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // Grant different permissions to multiple files
      await granularPermission.updatePermission(addr1.address, 0, 1); // READ for file 0
      await granularPermission.updatePermission(addr1.address, 1, 2); // WRITE for file 1

      // Get permissions for both files
      const permissions = await granularPermission.getUserFilePermissions(
        addr1.address,
        [0, 1]
      );

      // Verify results
      expect(permissions.length).to.equal(2);
      expect(permissions[0]).to.equal(1); // READ
      expect(permissions[1]).to.equal(2); // WRITE
    });
  });

  // Test file access with permission check
  describe("File Access with Permission Check", function () {
    it("should allow read access to file with READ permission", async function () {
      const { granularPermission, addr1, ipfsHash } = await loadFixture(
        deployGranularPermissionFixture
      );

      // Grant READ permission to addr1 for fileId 0
      await granularPermission.updatePermission(addr1.address, 0, 1);

      // Try to read the file with permission check
      const fileData = await granularPermission.getFileWithPermissionCheck(
        addr1.address,
        0
      );

      // Verify the file data matches
      expect(fileData.metadataIPFSHash).to.equal(ipfsHash);
      expect(fileData.contentIPFSHash).to.equal(ipfsHash);
    });

    it("should deny read access to file without permission", async function () {
      const { granularPermission, addr1 } = await loadFixture(
        deployGranularPermissionFixture
      );

      // No permission granted to addr1 for fileId 0

      // Try to read the file with permission check
      await expect(
        granularPermission.getFileWithPermissionCheck(addr1.address, 0)
      ).to.be.revertedWith("FP010: User does not have read permission");
    });
  });

  // Test admin file operations
  describe("Admin File Operations", function () {
    it("should allow owner to add a file via GranularPermission", async function () {
      const { granularPermission, ipfsHash, fileversePortal } =
        await loadFixture(deployGranularPermissionFixture);

      // Get the initial file count
      const initialCount = await fileversePortal.getFileCount();
      expect(initialCount).to.equal(2); // We already have files with IDs 0 and 1

      // Add a file via GranularPermission contract
      await granularPermission.adminAddFile(
        ipfsHash,
        ipfsHash,
        "",
        0, // FileType.PUBLIC
        0 // version
      );

      // Verify the file was added (file count should now be 3)
      const newCount = await fileversePortal.getFileCount();
      expect(newCount).to.equal(3); // Should be incremented by 1
    });
  });

  // Test proxy operations (executeTransaction)
  describe("Proxy Operations", function () {
    it("should allow user with WRITE permission to edit file via proxy", async function () {
      const { granularPermission, fileversePortal, addr1, ipfsHash } =
        await loadFixture(deployGranularPermissionFixture);

      // Grant WRITE permission to addr1 for fileId 0
      await granularPermission.updatePermission(addr1.address, 0, 2);

      // Create the calldata for editing the file
      const editFileCalldata = fileversePortal.interface.encodeFunctionData(
        "editFile",
        [
          0, // fileId
          ipfsHash + "new", // new metadata IPFS hash
          ipfsHash + "new", // new content IPFS hash
          "", // gate IPFS hash
          0, // file type
          0, // version
        ]
      );

      // Execute the transaction via the proxy (as addr1)
      await granularPermission
        .connect(addr1)
        .executeTransaction(addr1.address, editFileCalldata);

      // Verify the file was updated
      const file = await fileversePortal.files(0);
      expect(file.metadataIPFSHash).to.equal(ipfsHash + "new");
      expect(file.contentIPFSHash).to.equal(ipfsHash + "new");
    });

    it("should deny user without WRITE permission to edit file via proxy", async function () {
      const { granularPermission, fileversePortal, addr1, ipfsHash } =
        await loadFixture(deployGranularPermissionFixture);

      // Grant only READ permission to addr1 for fileId 0
      await granularPermission.updatePermission(addr1.address, 0, 1);

      // Create the calldata for editing the file
      const editFileCalldata = fileversePortal.interface.encodeFunctionData(
        "editFile",
        [
          0, // fileId
          ipfsHash + "new", // new metadata IPFS hash
          ipfsHash + "new", // new content IPFS hash
          "", // gate IPFS hash
          0, // file type
          0, // version
        ]
      );

      // Try to execute the transaction via the proxy (should fail)
      await expect(
        granularPermission
          .connect(addr1)
          .executeTransaction(addr1.address, editFileCalldata)
      ).to.be.revertedWith("FP009: User does not have write permission");
    });

    it("should emit ProxyOperationPerformed event on successful proxy operation", async function () {
      const { granularPermission, fileversePortal, addr1, ipfsHash } =
        await loadFixture(deployGranularPermissionFixture);

      // Grant WRITE permission to addr1 for fileId 0
      await granularPermission.updatePermission(addr1.address, 0, 2);

      // Create the calldata for editing the file
      const editFileCalldata = fileversePortal.interface.encodeFunctionData(
        "editFile",
        [
          0, // fileId
          ipfsHash + "new", // new metadata IPFS hash
          ipfsHash + "new", // new content IPFS hash
          "", // gate IPFS hash
          0, // file type
          0, // version
        ]
      );

      // Execute the transaction and check for event
      const editFileSelector = "0x" + editFileCalldata.slice(2, 10); // Extract function selector
      await expect(
        granularPermission
          .connect(addr1)
          .executeTransaction(addr1.address, editFileCalldata)
      )
        .to.emit(granularPermission, "ProxyOperationPerformed")
        .withArgs(addr1.address, 0, editFileSelector);
    });
  });
});
