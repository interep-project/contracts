import { getOAuthProviders, getReputationLevels } from "@interrep/reputation-criteria"
import { config as dotenvConfig } from "dotenv"
import { task, types } from "hardhat/config"
import { resolve } from "path"

dotenvConfig({ path: resolve(__dirname, "../.env") })

const depth = Number(process.env.MERKLE_TREE_DEPTH) || 16

task("groups", "Create the InterRep default groups")
    .addParam<string>("address", "The address of the contract")
    .addOptionalParam<number>("depth", "The depth of the trees", depth, types.int)
    .setAction(async ({ address, depth }, { ethers }): Promise<void> => {
        const contract = await ethers.getContractAt("Groups", address)
        const admin = await contract.signer.getAddress()
        const providers = getOAuthProviders()
        const reputationLevels = getReputationLevels()

        for (let provider of providers) {
            await contract.batchCreateGroup(
                ethers.utils.formatBytes32String(provider),
                reputationLevels.map(ethers.utils.formatBytes32String),
                reputationLevels.map(() => depth),
                reputationLevels.map(() => admin)
            )

            provider = (provider.charAt(0).toUpperCase() + provider.slice(1)) as any

            console.log(`${provider} groups created`)
        }
    })
