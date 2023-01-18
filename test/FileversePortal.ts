// import { expect } from "chai";
import { ethers } from "hardhat";

describe("Fileverse Portal", function () {
  it("should be able to deploy with correct number of parameters", async function () {
    const FileversePortal = await ethers.getContractFactory("FileversePortal");
    const metadataIPFSHash = "QmWSa5j5DbAfHvALWhrBgrcEkt5PAPVKLzcjuCAE8szQp5";
    const ownerViewDid =
      "did:key:z6MkkiKsFrxyb6mDd6RaWjDuuBs84T8vFtPgCds7jEC9bPbo";
    const ownerViewSecret =
      "fYRf/gRc0mIqLfb4RnBcqiMAHZFAwPGXupF10qnJLBldAiew/NMos/KMJgssYX0jodXuVTsSoQSv+XSBznRU6g==";
    const ownerEditDid =
      "did:key:z6MkjeNxGFLaSrTTRnQbDcfXytYb8wAZiY1yy1X2g678xuYD";
    const ownerEditSecret =
      "3/7BKTVqq8p6rgd24UBrdQ+WsGlG3KbBATPMjDF7iSpNI6J07LUqiULjBCSJ15BbzOddrsAU3UedJMUmge6T6g==";
    const owner = "0x6b8ddbA9c380e68201F76072523C4aC9AC4113ae";
    const trustedForwarder = "0x7EF22F49a2aE4a2E7c20369E6F7E5C9f94238141";

    const fileversePortal = await FileversePortal.deploy(
      metadataIPFSHash,
      ownerViewDid,
      ownerEditDid,
      owner,
      trustedForwarder
    );
    await fileversePortal.deployed();
  });
});
