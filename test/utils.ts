import { MerkleTree } from "@interrep/merkle-tree"
import { poseidon } from "circomlibjs"

export function createTree(depth: number, numberOfNodes = 0): MerkleTree {
    const tree = new MerkleTree(poseidon, depth)

    for (let i = 0; i < numberOfNodes; i++) {
        tree.insert(BigInt(i + 1))
    }

    return tree
}
