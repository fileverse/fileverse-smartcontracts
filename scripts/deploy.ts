// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, hardhatArguments } from "hardhat";
import fs from "fs";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const trustedForwarder = process.env.TRUSTED_FORWARDER; // trusted forwarder address

  if (!trustedForwarder) {
    throw new Error("trusted forwarder is not defined");
  }

  // We get the contract to deploy
  const FileversePortalRegistry = await ethers.getContractFactory(
    "FileversePortalRegistry"
  );

  const fileversePortalRegistryInstance = await FileversePortalRegistry.deploy(
    trustedForwarder
  );

  await fileversePortalRegistryInstance.deployed();

  const FileversePaymaster = await ethers.getContractFactory(
    "FileversePaymaster"
  );

  const fileversePaymasterInstance = await FileversePaymaster.deploy(
    fileversePortalRegistryInstance.address
  );

  await fileversePaymasterInstance.deployed();

  fs.writeFileSync(
    (hardhatArguments.network ?? "unknown") + ".json",
    JSON.stringify({
      paymaster: fileversePaymasterInstance.address,
      registry: fileversePortalRegistryInstance.address,
    })
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
