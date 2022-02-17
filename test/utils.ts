import { IncrementalMerkleTree } from "@zk-kit/incremental-merkle-tree"
import { poseidon } from "circomlibjs"
import { ethers } from "ethers"

export function createTree(depth: number, numberOfNodes = 0): IncrementalMerkleTree {
    const zeroValue = ethers.utils.solidityKeccak256(["string"], ["Semaphore"])
    const tree = new IncrementalMerkleTree(poseidon, depth, zeroValue, 2)

    for (let i = 0; i < numberOfNodes; i++) {
        tree.insert(BigInt(i + 1))
    }

    return tree
}
