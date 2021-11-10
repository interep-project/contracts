import { getOAuthProviders, getReputationLevels } from "@interrep/reputation-criteria"
import { task, types } from "hardhat/config"

task("groups", "Create the InterRep default groups")
    .addParam<string>("address", "The address of the contract")
    .addParam<number>("depth", "The depth of the trees", undefined, types.int)
    .setAction(async ({ address, depth }, { ethers }): Promise<void> => {
        const contract = await ethers.getContractAt("Groups", address)
        const admin = await contract.signer.getAddress()
        const providers = getOAuthProviders()
        const reputationLevels = getReputationLevels()

        for (const provider of providers) {
            for (const reputation of reputationLevels) {
                await contract.createGroup(
                    ethers.utils.formatBytes32String(provider),
                    ethers.utils.formatBytes32String(reputation),
                    depth,
                    admin
                )
            }
        }
    })
