import { ContractFactory } from "@ethersproject/contracts"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address"
import { expect } from "chai"
import { ethers, upgrades } from "hardhat"
import { InterRepGroups } from "../typechain"

describe("InterRepGroups", () => {
    let contract: InterRepGroups
    let owner: SignerWithAddress

    before(async () => {
        ;[owner] = await ethers.getSigners()
    })

    beforeEach(async () => {
        const contractFactory: ContractFactory = await ethers.getContractFactory("InterRepGroups")

        contract = (await upgrades.deployProxy(contractFactory)) as InterRepGroups

        await contract.deployed()
    })

    it("Should add a root hash", async () => {
        const groupId = ethers.utils.formatBytes32String("id")
        const identityCommitment = BigInt(2)
        const rootHash = BigInt(3)

        await contract.addRootHash(groupId, identityCommitment, rootHash)

        expect(await contract.rootHashes(groupId, 0)).to.eq(3)
    })
})
