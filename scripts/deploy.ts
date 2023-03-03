// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const TrustedForwarder = await ethers.getContractFactory("Forwarder"); // trusted forwarder address
  const trustedForwarder = await TrustedForwarder.deploy();
  await trustedForwarder.deployed();
  console.log("TrustedForwarder deployed to:", trustedForwarder.address);

  // We get the contract to deploy
  const FileversePortalRegistry = await ethers.getContractFactory(
    "FileversePortalRegistry"
  );
  const fileversePortalRegistry = await FileversePortalRegistry.deploy(
    trustedForwarder.address
  );
  await fileversePortalRegistry.deployed();
  console.log(
    "FileversePortalRegistry deployed to:",
    fileversePortalRegistry.address
  );

  const FileverseMember = await ethers.getContractFactory("FileverseMember");
  const fileverseMember = await FileverseMember.deploy();
  await fileverseMember.deployed();
  console.log("FileverseMember deployed to:", fileverseMember.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
