import { expect } from "chai"
import { ethers, run } from "hardhat"
import { OffchainGroups } from "../typechain"

describe("OffchainGroups", () => {
    let contract: OffchainGroups

    beforeEach(async () => {
        contract = await run("deploy:offchain-groups", { logs: false })
    })

    it("Should add a root hash", async () => {
        const provider = ethers.utils.formatBytes32String("twitter")
        const name = ethers.utils.formatBytes32String("gold")
        const identityCommitment = BigInt(2)
        const rootHash = BigInt(3)

        await contract.addRootHash(provider, name, identityCommitment, rootHash)

        const expectedRootHash = await contract.getRootHash(provider, name)

        expect(expectedRootHash).to.eq(rootHash)
    })

    it("Should add 3 root hashes in a single batch", async () => {
        const provider = ethers.utils.formatBytes32String("twitter")
        const names = ["gold", "silver", "bronze"].map(ethers.utils.formatBytes32String)
        const identityCommitments = [1, 2, 3].map(BigInt)
        const rootHashes = [1, 2, 3].map(BigInt)

        await contract.batchAddRootHash(provider, names, identityCommitments, rootHashes)

        const expectedRootHash = await contract.getRootHash(provider, names[0])

        expect(expectedRootHash).to.eq(rootHashes[0])
    })

    it("Should throw an error if the length of the array parameters is not the same", async () => {
        const provider = ethers.utils.formatBytes32String("twitter")
        const names = ["gold", "silver", "bronze"].map(ethers.utils.formatBytes32String)
        const identityCommitments = [1, 2].map(BigInt)
        const rootHashes = [1, 2, 3].map(BigInt)

        const fun = () => contract.batchAddRootHash(provider, names, identityCommitments, rootHashes)

        await expect(fun()).to.be.revertedWith("Array parameters should have the same length")
    })
})
