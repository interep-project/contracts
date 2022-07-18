import { Group, Member } from "@semaphore-protocol/group"
import { Identity } from "@semaphore-protocol/identity"
import { FullProof, generateProof, packToSolidityProof, SolidityProof } from "@semaphore-protocol/proof"
import { expect } from "chai"
import { config as dotenvConfig } from "dotenv"
import { utils } from "ethers"
import { run } from "hardhat"
import { resolve } from "path"
import { Interep } from "../build/typechain/Interep"
import { createGroupId, createIdentityCommitments } from "./utils"

dotenvConfig({ path: resolve(__dirname, "../.env") })

describe("Interep", () => {
    let contract: Interep

    const groupProvider = utils.formatBytes32String("provider")
    const groupName = utils.formatBytes32String("name")
    const groupId = createGroupId(groupProvider, groupName)
    const group = new Group()
    const members = createIdentityCommitments(3)

    const wasmFilePath = "./static/semaphore.wasm"
    const zkeyFilePath = "./static/semaphore.zkey"

    group.addMembers(members)

    before(async () => {
        const { address: verifierAddress } = await run("deploy:verifier", { logs: false })
        contract = await run("deploy:interep", {
            logs: false,
            verifiers: [{ merkleTreeDepth: group.depth, contractAddress: verifierAddress }]
        })
    })

    describe("# updateGroups", () => {
        it("Should not publish new Interep groups if there is an unsupported tree depth", async () => {
            const transaction = contract.updateGroups([
                { provider: groupProvider, name: groupName, root: 1, depth: 10 }
            ])

            await expect(transaction).to.be.revertedWith("Interep: tree depth is not supported")
        })

        it("Should publish 20 new Interep groups", async () => {
            const groups: { provider: string; name: string; root: Member; depth: number }[] = []

            for (let i = 0; i < 20; i++) {
                groups.push({
                    provider: groupProvider,
                    name: groupName,
                    root: group.root,
                    depth: group.depth
                })
            }

            const transaction = contract.updateGroups(groups)

            await expect(transaction)
                .to.emit(contract, "GroupUpdated")
                .withArgs(groupId, groups[0].provider, groups[0].name, groups[0].root, groups[0].depth)
            expect((await (await transaction).wait()).events).to.length(20)
        })
    })

    describe("# getRoot", () => {
        it("Should get the tree root of an Interep group", async () => {
            const root = await contract.getRoot(groupId)

            expect(root).to.equal("10984560832658664796615188769057321951156990771630419931317114687214058410144")
        })
    })

    describe("# getOffchainDepth", () => {
        it("Should get the tree depth of an Interep group", async () => {
            const root = await contract.getDepth(groupId)

            expect(root).to.equal(group.depth)
        })
    })

    describe("# verifyProof", () => {
        const signal = "Hello world"
        const bytes32Signal = utils.formatBytes32String(signal)
        const identity = new Identity("0")

        let fullProof: FullProof
        let solidityProof: SolidityProof

        before(async () => {
            fullProof = await generateProof(identity, group, group.root, signal, { zkeyFilePath, wasmFilePath })
            solidityProof = packToSolidityProof(fullProof.proof)
        })

        it("Should not verify a proof if the group does not exist", async () => {
            const transaction = contract.verifyProof(10, bytes32Signal, 0, 0, [0, 0, 0, 0, 0, 0, 0, 0])

            await expect(transaction).to.be.revertedWith("Interep: group does not exist")
        })

        it("Should throw an exception if the proof is not valid", async () => {
            const transaction = contract.verifyProof(
                groupId,
                bytes32Signal,
                fullProof.publicSignals.nullifierHash,
                0,
                solidityProof
            )

            await expect(transaction).to.be.revertedWith("InvalidProof()")
        })

        it("Should verify a proof for an onchain group correctly", async () => {
            const transaction = contract.verifyProof(
                groupId,
                bytes32Signal,
                fullProof.publicSignals.nullifierHash,
                fullProof.publicSignals.merkleRoot,
                solidityProof
            )

            await expect(transaction).to.emit(contract, "ProofVerified").withArgs(groupId, bytes32Signal)
        })
    })
})
