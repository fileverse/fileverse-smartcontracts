// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

const tokenContract = "0x58318a309d762a28E0a40BB383c283DdD60bAa3C";
const relayer = "0x9fa87c9a078Cf87391E10edF96F65Cb2f4A794de";

async function main() {
  const FileverseMember = await ethers.getContractFactory("FileverseMember");
  const fileverseMember = await FileverseMember.attach(tokenContract);
  const role = await fileverseMember.MINTER_ROLE();
  await fileverseMember.grantRole(role, relayer);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
