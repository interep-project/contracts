import { IncrementalQuinTree } from "incrementalquintree"

export function createTree(depth: number, poseidon: any, numberOfNodes = 0): IncrementalQuinTree {
    const tree = new IncrementalQuinTree(depth, 0, 2, (inputs: BigInt[]) => poseidon.F.toObject(poseidon(inputs)))

    for (let i = 0; i < numberOfNodes; i++) {
        tree.insert(BigInt(i + 1))
    }

    return tree
}

export function getPath(tree: IncrementalQuinTree, index: number) {
    const { indices, pathElements, root } = tree.genMerklePath(index)
    const siblingNodes = pathElements.map((e: BigInt[]) => e[0])

    return {
        siblingNodes,
        positions: indices,
        root
    }
}
