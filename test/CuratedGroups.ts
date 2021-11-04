import { expect } from "chai"
import { ethers, run } from "hardhat"
import { CuratedGroups } from "../typechain"

describe("CuratedGroups", () => {
    let contract: CuratedGroups

    before(async () => {
        contract = await run("deploy:curated-groups", { logs: false })
    })

    it("Should create a group", async () => {
        const groupId = ethers.utils.formatBytes32String("groupId")

        await contract.createGroup(groupId, 16)

        const { depth } = await contract.groups(groupId)

        expect(depth).to.eq(16)
    })

    it("Should not create a group with an existing id", async () => {
        const groupId = ethers.utils.formatBytes32String("groupId")

        const fun = () => contract.createGroup(groupId, 16)

        await expect(fun()).to.be.revertedWith("The group already exists")
    })

    it("Should not add an identity commitment if the group does not exist", async () => {
        const groupId = ethers.utils.formatBytes32String("groupId1")
        const identityCommitment = BigInt(2)

        const fun = () => contract.addIdentityCommitment(groupId, identityCommitment)

        await expect(fun()).to.be.revertedWith("The group does not exist")
    })

    it("Should add an identity commitment in a group", async () => {
        const groupId = ethers.utils.formatBytes32String("groupId")
        const identityCommitment = BigInt(
            "2825646560483793878176284075509449079260676404272675066033690163469311186662"
        )

        await contract.addIdentityCommitment(groupId, identityCommitment)

        const { numberOfLeaves, root } = await contract.groups(groupId)

        expect(numberOfLeaves).to.eq(1)
        expect(root.toString()).to.eq("13636421308146043413489220009267735248703575391714290025204419877115892930915")
    })
})
