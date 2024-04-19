import {ethers} from "hardhat";
import jsonFactory from '../artifacts/contracts/factory/IdFactory.sol/IdFactory.json';

async function main() {
  const [claimIssuerOwner] = await ethers.getSigners();

  // const claimIssuer = await ethers.deployContract("ClaimIssuer", [claimIssuerOwner.address]);
  //
  // console.log(`Deploying Claim Issuer at ${claimIssuer.address} ...`);
  //
  // await claimIssuer.deployed();
  //
  // console.log(`Deployed Claim Issuer ${claimIssuer.address} !`);

  const contractAdresses = ['0x79fe9033f56b2f269f0035dea5bd09b9ce36c06b58810a803a35045f51b5585e', '0xdb10c278e8be74a6f548b72900118f961f3f0d9a690fa7d7ed0cb9cc5d707957', '0x0a979d6becf36eb9192752c5f5ab5435bcd9fe29cd5ccf20bdf8486c13c0fbc9'];


  for (const i in contractAdresses) {
    const wallet = new ethers.Wallet(contractAdresses[i]);

    console.log(wallet.address);

    const claimIssuer = await ethers.deployContract("ClaimIssuer", [wallet.address]);

    console.log(`Deploying Claim Issuer at ${claimIssuer.address} ...`);

    await claimIssuer.deployed();

    console.log(`Deployed Claim Issuer for wallet ${wallet.address} at address ${claimIssuer.address} !`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
