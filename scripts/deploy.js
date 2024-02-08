import { ethers } from "hardhat";
async function main() {
  const [owner] = await ethers.getSigners();

//   const deployNftContract = await ethers.getContractFactory("MyToken");
//   const deployednftcontract = await deployNftContract.deploy();
//   await deployednftcontract.connect(owner).deployed();

  const deployContract = await hre.ethers.getContractFactory("NFT_MarketPlace");
  const deployedContract = await deployContract.deploy();
//  await deployContract.connect(owner).deployed();

 // console.log("The Address of this contract is:", deployednftcontract.address);
  console.log("The Address of this contract is:", deployedContract.address);

}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
