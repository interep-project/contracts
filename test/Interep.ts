import { expect } from "chai"
import { config as dotenvConfig } from "dotenv"
import { BytesLike, Signer } from "ethers"
import { ethers, run } from "hardhat"
import { resolve } from "path"
import { Interep } from "../build/typechain/Interep"
import { createTree } from "./utils"

dotenvConfig({ path: resolve(__dirname, "../.env") })

describe("Interep", () => {
    let contract: Interep
    let signers: Signer[]
    let accounts: string[]

    const provider = ethers.utils.formatBytes32String("twitter")
    const name = ethers.utils.formatBytes32String("gold")
    const groupId = ethers.utils.formatBytes32String("groupId")
    const member = BigInt(1)
    const depth = Number(process.env.MERKLE_TREE_DEPTH) || 16

    before(async () => {
        contract = await run("deploy", { logs: false })

        signers = await run("accounts", { logs: false })
        accounts = await Promise.all(signers.map((signer: Signer) => signer.getAddress()))
    })

    it("Should not publish new offchain roots if the parameter lists don't have the same length", async () => {
        const transaction = contract.addOffchainRoots([provider], [name], [BigInt(1), BigInt(2)])

        await expect(transaction).to.be.revertedWith("Groups: parameters lists does not have the same length")
    })

    it("Should publish 20 new offchain roots", async () => {
        const providers: BytesLike[] = []
        const names: BytesLike[] = []
        const roots: bigint[] = []

        for (let i = 0; i < 20; i++) {
            providers.push(provider)
            names.push(name)
            roots.push(BigInt(i))
        }

        const transaction = contract.addOffchainRoots(providers, names, roots)

        await expect(transaction).to.emit(contract, "OffchainRoot").withArgs(provider, name, roots[0])
        expect((await (await transaction).wait()).events).to.length(20)
    })

    it("Should get the root of an offchain group", async () => {
        const root = await contract.getOffchainRoot(provider, name)

        expect(root).to.equal("19")
    })

    it("Should create a group", async () => {
        const transaction = contract.createGroup(groupId, depth, accounts[0])

        await expect(transaction).to.emit(contract, "GroupAdded").withArgs(groupId, depth)
    })

    it("Should not add a member if the caller is not the group admin", async () => {
        const member = BigInt(2)

        const transaction = contract.connect(signers[1]).addMember(groupId, member)

        await expect(transaction).to.be.revertedWith("Interep: caller is not the group admin")
    })

    it("Should add a new member in an existing group", async () => {
        const transaction = contract.addMember(groupId, member)

        await expect(transaction)
            .to.emit(contract, "MemberAdded")
            .withArgs(groupId, member, "20934463675547667411856398545159532828742529822605677213798898733932461758379")
    })

    it("Should not remove a member if the caller is not the group admin", async () => {
        const transaction = contract.connect(signers[1]).removeMember(groupId, member, [0, 1], [0, 1])

        await expect(transaction).to.be.revertedWith("Interep: caller is not the group admin")
    })

    it("Should remove a member from an existing group", async () => {
        const groupId = ethers.utils.formatBytes32String("hello")
        const tree = createTree(depth, 3)

        tree.delete(0)

        await contract.createGroup(groupId, depth, accounts[0])
        await contract.addMember(groupId, BigInt(1))
        await contract.addMember(groupId, BigInt(2))
        await contract.addMember(groupId, BigInt(3))

        const { siblings, pathIndices, root } = tree.createProof(0)

        const transaction = contract.removeMember(
            groupId,
            BigInt(1),
            siblings.map((s) => s[0]),
            pathIndices
        )

        await expect(transaction).to.emit(contract, "MemberRemoved").withArgs(groupId, BigInt(1), root)
    })
})
