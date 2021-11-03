import { expect } from "chai"
import { ethers, run } from "hardhat"
import { CuratedGroups } from "../typechain"

describe("CuratedGroups", () => {
    let contract: CuratedGroups

    beforeEach(async () => {
        contract = await run("deploy:curated-groups", { logs: false })
    })

    it("Should add an identity commitment in a group", async () => {
        const groupId = ethers.utils.formatBytes32String("gold")
        const identityCommitment = BigInt(2)

        await contract.insertLeaf(groupId, identityCommitment)

        const { nextLeafIndex } = await contract.groups(groupId)

        expect(nextLeafIndex).to.eq(1)
    })
})
