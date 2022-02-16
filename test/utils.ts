import { IncrementalMerkleTree } from "@zk-kit/incremental-merkle-tree"
import { poseidon } from "circomlibjs"

export function createTree(depth: number, numberOfNodes = 0): IncrementalMerkleTree {
    const tree = new IncrementalMerkleTree(poseidon, depth, BigInt(0), 2)

    for (let i = 0; i < numberOfNodes; i++) {
        tree.insert(BigInt(i + 1))
    }

    return tree
}
