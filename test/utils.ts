import { Strategy, ZkIdentity } from "@zk-kit/identity"
import { IncrementalMerkleTree } from "@zk-kit/incremental-merkle-tree"
import { poseidon } from "circomlibjs"
import { ethers } from "ethers"

export function createTree(depth: number, n = 0): IncrementalMerkleTree {
    const zeroValue = ethers.utils.solidityKeccak256(["string"], ["Semaphore"])
    const tree = new IncrementalMerkleTree(poseidon, depth, zeroValue, 2)

    for (let i = 0; i < n; i++) {
        tree.insert(BigInt(i + 1))
    }

    return tree
}

export function createIdentityCommitments(n: number): bigint[] {
    const identityCommitments: bigint[] = []

    for (let i = 0; i < n; i++) {
        const identity = new ZkIdentity(Strategy.MESSAGE, i.toString())
        const identityCommitment = identity.genIdentityCommitment()

        identityCommitments.push(identityCommitment)
    }

    return identityCommitments
}
