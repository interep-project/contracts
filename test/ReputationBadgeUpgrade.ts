import hre from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address"
import { expect } from "chai"
import { Contract, ContractFactory } from "@ethersproject/contracts"

const { ethers, upgrades } = hre

describe("ReputationBadge upgrade", () => {
    let badge: Contract
    let badgeTestV2: Contract
    let deployer: SignerWithAddress
    let backend: SignerWithAddress
    let signer1: SignerWithAddress

    const badgeName = "TwitterBadge"
    const badgeSymbol = "iTWITT"

    before(async () => {
        ;[deployer, backend, signer1] = await hre.ethers.getSigners()
    })

    beforeEach(async () => {
        const BadgeFactory: ContractFactory = await ethers.getContractFactory("ReputationBadge")
        const BadgeV2Factory: ContractFactory = await ethers.getContractFactory("ReputationBadgeV2Test")

        badge = await upgrades.deployProxy(BadgeFactory, [badgeName, badgeSymbol, backend.address])
        badgeTestV2 = await upgrades.upgradeProxy(badge.address, BadgeV2Factory)
    })

    it("should return from the new function", async () => {
        expect(await badgeTestV2.thisIsATest()).to.eq(42)
    })

    it("should return the badge name", async () => {
        expect(await badgeTestV2.name()).to.eq(badgeName)
    })

    it("should return the badge symbol", async () => {
        expect(await badgeTestV2.symbol()).to.eq(badgeSymbol)
    })

    it("should let the deployer pause", async () => {
        await badge.connect(deployer).pause()

        expect(await badge.paused()).to.be.true
    })

    it("should let the backend mint a token", async () => {
        await badge.connect(backend).safeMint(signer1.address, 1)

        expect(await badge.balanceOf(signer1.address)).to.eq(1)
        expect(await badge.ownerOf(1)).to.eq(signer1.address)
    })

    it("should only let the backend mint a token", async () => {
        await expect(badge.connect(signer1).safeMint(signer1.address, 234)).to.be.revertedWith("Unauthorized")
    })

    it("should let the deployer change the backend address", async () => {
        // change backend address
        const tx = await badge.connect(deployer).changeBackendAddress(signer1.address)
        await tx.wait()

        // check backendAddress was changed
        expect(await badge.backendAddress()).to.eq(signer1.address)
    })

    it("should only let the deployer change the backend address", async () => {
        await expect(badge.connect(signer1).changeBackendAddress(signer1.address)).to.be.revertedWith(
            "Ownable: caller is not the owner"
        )
    })
})
