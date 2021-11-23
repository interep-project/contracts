import { expect } from "chai"
import { config as dotenvConfig } from "dotenv"
import { Signer } from "ethers"
import { ethers, run } from "hardhat"
import { resolve } from "path"
import { Groups } from "../typechain"
import { createTree } from "./utils"

dotenvConfig({ path: resolve(__dirname, "../.env") })

describe("Groups", () => {
    let contract: Groups
    let signers: Signer[]
    let accounts: string[]

    const provider = ethers.utils.formatBytes32String("twitter")
    const name = ethers.utils.formatBytes32String("gold")
    const identityCommitment = BigInt(1)
    const depth = Number(process.env.MERKLE_TREE_DEPTH) || 16

    before(async () => {
        contract = await run("deploy:groups", { logs: false })

        signers = await run("accounts", { logs: false })
        accounts = await Promise.all(signers.map((signer: Signer) => signer.getAddress()))
    })

    it("Should not create a group with a depth > 32", async () => {
        const fun = () => contract.createGroup(provider, name, 33, accounts[0])

        await expect(fun()).to.be.revertedWith("IncrementalTree: tree depth must be between 1 and 32")
    })

    it("Should create a group", async () => {
        const fun = () => contract.createGroup(provider, name, depth, accounts[0])

        await expect(fun()).to.emit(contract, "GroupAdded").withArgs(provider, name, depth)
    })

    it("Should not create a group with an existing id", async () => {
        const fun = () => contract.createGroup(provider, name, depth, accounts[0])

        await expect(fun()).to.be.revertedWith("Groups: group already exists")
    })

    it("Should get the root of the group", async () => {
        const root = await contract.getRoot(provider, name)

        expect(root).to.equal(0)
    })

    it("Should get the size of the group", async () => {
        const size = await contract.getSize(provider, name)

        expect(size).to.equal(0)
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

    it("Should not add an identity commitment if its value is > SNARK_SCALAR_FIELD", async () => {
        const identityCommitment = BigInt(
            "21888242871839275222246405745257275088548364400416034343698204186575808495618"
        )

        const fun = () => contract.addIdentityCommitment(provider, name, identityCommitment)

        await expect(fun()).to.be.revertedWith("IncrementalTree: leaf must be < SNARK_SCALAR_FIELD")
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

    it("Should not add an identity commitment if the group is full", async () => {
        const name = ethers.utils.formatBytes32String("tinyGroup")

        await contract.createGroup(provider, name, 1, accounts[0])
        await contract.addIdentityCommitment(provider, name, identityCommitment)
        await contract.addIdentityCommitment(provider, name, identityCommitment)

        const fun = () => contract.addIdentityCommitment(provider, name, identityCommitment)

        await expect(fun()).to.be.revertedWith("IncrementalTree: tree is full")
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

    it("Should not delete an identity commitment if its value is > SNARK_SCALAR_FIELD", async () => {
        const identityCommitment = BigInt(
            "21888242871839275222246405745257275088548364400416034343698204186575808495618"
        )

        const fun = () => contract.deleteIdentityCommitment(provider, name, identityCommitment, [0, 1], [0, 1])

        await expect(fun()).to.be.revertedWith("IncrementalTree: leaf must be < SNARK_SCALAR_FIELD")
    })

    it("Should delete an identity commitment", async () => {
        const name = ethers.utils.formatBytes32String("hello")
        const tree = createTree(depth, 3)

        tree.delete(0)

        await contract.createGroup(provider, name, depth, accounts[0])
        await contract.addIdentityCommitment(provider, name, BigInt(1))
        await contract.addIdentityCommitment(provider, name, BigInt(2))
        await contract.addIdentityCommitment(provider, name, BigInt(3))

        const { siblingNodes, path, root } = tree.createProof(0)

        const fun = () => contract.deleteIdentityCommitment(provider, name, BigInt(1), siblingNodes as bigint[], path)

        await expect(fun()).to.emit(contract, "IdentityCommitmentDeleted").withArgs(provider, name, BigInt(1), root)
    })

    it("Should delete another identity commitment", async () => {
        const name = ethers.utils.formatBytes32String("hello")
        const tree = createTree(depth, 3)

        tree.delete(0)
        tree.delete(1)

        const { siblingNodes, path, root } = tree.createProof(1)

        const fun = () => contract.deleteIdentityCommitment(provider, name, BigInt(2), siblingNodes as bigint[], path)

        await expect(fun()).to.emit(contract, "IdentityCommitmentDeleted").withArgs(provider, name, BigInt(2), root)
    })

    it("Should not delete an identity commitment that does not exist", async () => {
        const name = ethers.utils.formatBytes32String("hello")
        const tree = createTree(depth, 3)

        tree.delete(0)
        tree.delete(1)

        const { siblingNodes, path } = tree.createProof(0)

        const fun = () => contract.deleteIdentityCommitment(provider, name, BigInt(4), siblingNodes as bigint[], path)

        await expect(fun()).to.be.revertedWith("IncrementalTree: leaf is not part of the tree")
    })

    it("Should add an identity commitment in a group after a deletion", async () => {
        const name = ethers.utils.formatBytes32String("hello")
        const tree = createTree(depth, 4)

        tree.delete(0)
        tree.delete(1)

        const fun = () => contract.addIdentityCommitment(provider, name, BigInt(4))

        await expect(fun()).to.emit(contract, "IdentityCommitmentAdded").withArgs(provider, name, BigInt(4), tree.root)
    })

    it("Should add 4 identity commitments and delete them all", async () => {
        const name = ethers.utils.formatBytes32String("complex")
        const tree = createTree(depth, 4)

        await contract.createGroup(provider, name, depth, accounts[0])

        for (let i = 0; i < 4; i++) {
            await contract.addIdentityCommitment(provider, name, BigInt(i + 1))
        }

        for (let i = 0; i < 4; i++) {
            tree.delete(i)

            const { siblingNodes, path } = tree.createProof(i)

            await contract.deleteIdentityCommitment(provider, name, BigInt(i + 1), siblingNodes as bigint[], path)
        }

        const root = await contract.getRoot(provider, name)

        expect(root).to.equal(tree.root)
    })
})
