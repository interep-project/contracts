import { ContractFactory } from "@ethersproject/contracts"
import { expect } from "chai"
import { ethers, upgrades } from "hardhat"
import { InterRepGroups } from "../typechain"

describe("InterRepGroups", () => {
    let contract: InterRepGroups

    beforeEach(async () => {
        const contractFactory: ContractFactory = await ethers.getContractFactory("InterRepGroups")

        contract = (await upgrades.deployProxy(contractFactory)) as InterRepGroups

        await contract.deployed()
    })

    it("Should add a root hash correctly", async () => {
        const provider = ethers.utils.formatBytes32String("twitter")
        const name = ethers.utils.formatBytes32String("gold")
        const identityCommitment = BigInt(2)
        const rootHash = BigInt(3)

        await contract.addRootHash(provider, name, identityCommitment, rootHash)

        const expectedRootHash = await contract.getRootHash(provider, name)

        expect(expectedRootHash).to.eq(rootHash)
    })
})
