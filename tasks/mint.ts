import { task } from "hardhat/config"

task("mint", "Mint a token in the ReputationBadge contract")
    .addParam("contractAddress", "The address of the ReputationBadge contract")
    .addParam("to", "The address of the token owner")
    .addParam("tokenId", "The id of the token")
    .setAction(async ({ contractAddress, to, tokenId }, { ethers }) => {
        const [signer] = await ethers.getSigners()
        const reputationBadge = await ethers.getContractAt("ReputationBadge", contractAddress)

        await reputationBadge.connect(signer).safeMint(to, tokenId)

        console.log(`The token has been minted correctly`)
    })
