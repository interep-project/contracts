import { task } from "hardhat/config"

task("deploy:offchain-groups", "Deploy an OffchainGroups contract").setAction(async (args, { ethers, upgrades }) => {
    const ContractFactory = await ethers.getContractFactory("OffchainGroups")

    const contract = await upgrades.deployProxy(ContractFactory)

    await contract.deployed()

    console.log(`The OffchainGroups contract has been deployed to the address: ${contract.address}`)
})
