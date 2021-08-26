import { task } from "hardhat/config";
import { ReputationBadge } from "../typechain";

task("mint", "Mint a token in the ReputationBadge contract")
  .addParam("contractAddress", "The address of the ReputationBadge contract")
  .addParam("to", "The address of the token owner")
  .addParam("tokenId", "The id of the token")
  .setAction(async ({ contractAddress, to, tokenId }, { ethers }) => {
    const [signer] = await ethers.getSigners();
    const reputationBadge: ReputationBadge = (await ethers.getContractAt(
      "ReputationBadge",
      contractAddress,
    )) as ReputationBadge;

    await reputationBadge.connect(signer).safeMint(to, tokenId);

    console.log(`The token has been minted correctly`);
  });
