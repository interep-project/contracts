import { expect } from "chai"
import { Signer } from "ethers"
import { buildPoseidon } from "circomlibjs"
import { ethers, run } from "hardhat"
import { IncrementalQuinTree } from "incrementalquintree"
import { Groups } from "../typechain"

describe("Groups", () => {
    let contract: Groups
    let signers: Signer[]
    let accounts: string[]

    const provider = ethers.utils.formatBytes32String("twitter")
    const name = ethers.utils.formatBytes32String("gold")
    const identityCommitment = BigInt(1)

    before(async () => {
        contract = await run("deploy:groups", { logs: false })

        signers = await run("accounts", { logs: false })
        accounts = await Promise.all(signers.map((signer: Signer) => signer.getAddress()))
    })

    it("Should create a group", async () => {
        const fun = () => contract.createGroup(provider, name, 16, accounts[0])

        await expect(fun()).to.emit(contract, "GroupAdded").withArgs(provider, name, 16)
    })

    it("Should not create a group with an existing id", async () => {
        const fun = () => contract.createGroup(provider, name, 16, accounts[0])

        await expect(fun()).to.be.revertedWith("Groups: group already exists")
    })

    it("Should not add an identity commitment if the group does not exist", async () => {
        const name = ethers.utils.formatBytes32String("silver")

        const fun = () => contract.addIdentityCommitment(provider, name, identityCommitment)

        await expect(fun()).to.be.revertedWith("Groups: group does not exist")
    })

    it("Should not add an identity commitment if the caller is not the group admin", async () => {
        const identityCommitment = BigInt(2)

        const fun = () => contract.connect(signers[1]).addIdentityCommitment(provider, name, identityCommitment)

        await expect(fun()).to.be.revertedWith("Groups: caller is not the group admin")
    })

    it("Should add an identity commitment in a group", async () => {
        const fun = () => contract.addIdentityCommitment(provider, name, identityCommitment)

        await expect(fun())
            .to.emit(contract, "IdentityCommitmentAdded")
            .withArgs(
                provider,
                name,
                identityCommitment,
                "16211261537006706331557500769845541584780950636316907182067421710925347020533"
            )
    })

    it("Should throw an error if the length of the array parameters is not the same", async () => {
        const names = ["gold", "silver", "bronze"].map(ethers.utils.formatBytes32String)
        const identityCommitments = [1, 2].map(BigInt)

        const fun = () => contract.batchAddIdentityCommitment(provider, names, identityCommitments)

        await expect(fun()).to.be.revertedWith("Groups: array parameters should have the same length")
    })

    it("Should add 3 identity commitments in a single batch", async () => {
        const names = ["gold", "silver", "bronze"].map(ethers.utils.formatBytes32String)
        const identityCommitments = [1, 2, 3].map(BigInt)

        await contract.createGroup(provider, names[1], 16, accounts[0])
        await contract.createGroup(provider, names[2], 16, accounts[0])

        const fun = () => contract.batchAddIdentityCommitment(provider, names, identityCommitments)

        await expect(fun()).to.emit(contract, "IdentityCommitmentAdded")
    })

    it("Should not delete an identity commitment if the group does not exist", async () => {
        const name = ethers.utils.formatBytes32String("none")

        const fun = () => contract.deleteIdentityCommitment(provider, name, identityCommitment, [0, 1], [0, 1])

        await expect(fun()).to.be.revertedWith("Groups: group does not exist")
    })

    it("Should not delete an identity commitment if the caller is not the group admin", async () => {
        const identityCommitment = BigInt(2)

        const fun = () =>
            contract.connect(signers[1]).deleteIdentityCommitment(provider, name, identityCommitment, [0, 1], [0, 1])

        await expect(fun()).to.be.revertedWith("Groups: caller is not the group admin")
    })

    it("Should delete an identity commitment in a group", async () => {
        const name = ethers.utils.formatBytes32String("hello")
        const poseidon = await buildPoseidon()
        const tree = new IncrementalQuinTree(16, 0, 2, (inputs: BigInt[]) => poseidon.F.toObject(poseidon(inputs)))

        tree.insert(identityCommitment)
        tree.insert(BigInt(2))
        tree.insert(BigInt(3))

        await contract.createGroup(provider, name, 16, accounts[0])
        await contract.addIdentityCommitment(provider, name, identityCommitment)
        await contract.addIdentityCommitment(provider, name, BigInt(2))
        await contract.addIdentityCommitment(provider, name, BigInt(3))

        tree.update(0, 0)

        const { root, indices, pathElements } = tree.genMerklePath(0)
        const siblingNodes = pathElements.map((e: BigInt[]) => e[0])

        const fun = () => contract.deleteIdentityCommitment(provider, name, identityCommitment, siblingNodes, indices)

        await expect(fun())
            .to.emit(contract, "IdentityCommitmentDeleted")
            .withArgs(provider, name, identityCommitment, root)
    })

    it("Should add an identity commitment in a group after a deletion", async () => {
        const name = ethers.utils.formatBytes32String("hello")
        const poseidon = await buildPoseidon()
        const tree = new IncrementalQuinTree(16, 0, 2, (inputs: BigInt[]) => poseidon.F.toObject(poseidon(inputs)))

        tree.insert(identityCommitment)
        tree.insert(BigInt(2))
        tree.insert(BigInt(3))

        const fun = () => contract.addIdentityCommitment(provider, name, BigInt(4))

        tree.update(0, 0)
        tree.insert(BigInt(4))

        const { root } = tree.genMerklePath(0)

        await expect(fun()).to.emit(contract, "IdentityCommitmentAdded").withArgs(provider, name, BigInt(4), root)
    })
})
