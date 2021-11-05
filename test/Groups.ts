import { expect } from "chai"
import { ethers, run } from "hardhat"
import { Groups } from "../typechain"

describe("Groups", () => {
    let contract: Groups

    const provider = ethers.utils.formatBytes32String("twitter")
    const name = ethers.utils.formatBytes32String("gold")

    before(async () => {
        contract = await run("deploy:groups", { logs: false })
    })

    it("Should create a group", async () => {
        const fun = () => contract.createGroup(provider, name, 16)

        await expect(fun()).to.emit(contract, "NewGroup").withArgs(provider, name, 16)
    })

    it("Should not create a group with an existing id", async () => {
        const fun = () => contract.createGroup(provider, name, 16)

        await expect(fun()).to.be.revertedWith("The group already exists")
    })

    it("Should not add an identity commitment if the group does not exist", async () => {
        const identityCommitment = BigInt(2)
        const otherName = ethers.utils.formatBytes32String("silver")

        const fun = () => contract.addIdentityCommitment(provider, otherName, identityCommitment)

        await expect(fun()).to.be.revertedWith("The group does not exist")
    })

    it("Should add an identity commitment in a group", async () => {
        const identityCommitment = BigInt(
            "2825646560483793878176284075509449079260676404272675066033690163469311186662"
        )

        const fun = () => contract.addIdentityCommitment(provider, name, identityCommitment)

        await expect(fun())
            .to.emit(contract, "NewIdentityCommitment")
            .withArgs(
                provider,
                name,
                identityCommitment,
                "13636421308146043413489220009267735248703575391714290025204419877115892930915"
            )
    })

    it("Should throw an error if the length of the array parameters is not the same", async () => {
        const names = ["gold", "silver", "bronze"].map(ethers.utils.formatBytes32String)
        const identityCommitments = [1, 2].map(BigInt)

        const fun = () => contract.batchAddIdentityCommitment(provider, names, identityCommitments)

        await expect(fun()).to.be.revertedWith("Array parameters should have the same length")
    })

    it("Should add 3 root hashes in a single batch", async () => {
        const names = ["gold", "silver", "bronze"].map(ethers.utils.formatBytes32String)
        const identityCommitments = [1, 2, 3].map(BigInt)

        await contract.createGroup(provider, names[1], 16)
        await contract.createGroup(provider, names[2], 16)

        const fun = () => contract.batchAddIdentityCommitment(provider, names, identityCommitments)

        await expect(fun()).to.emit(contract, "NewIdentityCommitment")
    })
})
