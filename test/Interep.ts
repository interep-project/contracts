import { Strategy, ZkIdentity } from "@zk-kit/identity"
import { Semaphore, SemaphoreFullProof, SemaphoreSolidityProof } from "@zk-kit/protocols"
import { expect } from "chai"
import { config as dotenvConfig } from "dotenv"
import { utils } from "ethers"
import { run } from "hardhat"
import { resolve } from "path"
import { Interep } from "../build/typechain/Interep"
import { createGroupId, createIdentityCommitments, createTree } from "./utils"

dotenvConfig({ path: resolve(__dirname, "../.env") })

describe("Interep", () => {
    let contract: Interep

    const groupProvider = utils.formatBytes32String("provider")
    const groupName = utils.formatBytes32String("name")
    const groupId = createGroupId(groupProvider, groupName)
    const tree = createTree(20)
    const members = createIdentityCommitments(3)

    const wasmFilePath = "./static/semaphore.wasm"
    const finalZkeyPath = "./static/semaphore_final.zkey"

    for (const member of members) {
        tree.insert(member)
    }

    before(async () => {
        const { address: verifierAddress } = await run("deploy:verifier", { logs: false })
        contract = await run("deploy:interep", {
            logs: false,
            verifiers: [{ merkleTreeDepth: tree.depth, contractAddress: verifierAddress }]
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
            const groups: { provider: string; name: string; root: number; depth: number }[] = []

            for (let i = 0; i < 20; i++) {
                groups.push({
                    provider: groupProvider,
                    name: groupName,
                    root: tree.root,
                    depth: tree.depth
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

            expect(root).to.equal(tree.depth)
        })
    })

    describe("# verifyProof", () => {
        const signal = "Hello world"
        const bytes32Signal = utils.formatBytes32String(signal)
        const identity = new ZkIdentity(Strategy.MESSAGE, "0")
        const merkleProof = tree.createProof(0)
        const witness = Semaphore.genWitness(
            identity.getTrapdoor(),
            identity.getNullifier(),
            merkleProof,
            merkleProof.root,
            signal
        )

        let fullProof: SemaphoreFullProof
        let solidityProof: SemaphoreSolidityProof

        before(async () => {
            fullProof = await Semaphore.genProof(witness, wasmFilePath, finalZkeyPath)
            solidityProof = Semaphore.packToSolidityProof(fullProof.proof)
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
