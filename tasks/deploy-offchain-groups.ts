import { Contract } from "ethers"
import { task, types } from "hardhat/config"

task("deploy:offchain-groups", "Deploy an OffchainGroups contract")
    .addOptionalParam<boolean>("logs", "Print the logs", true, types.boolean)
    .setAction(async ({ logs }, { ethers, upgrades }): Promise<Contract> => {
        const ContractFactory = await ethers.getContractFactory("OffchainGroups")

        const contract = await upgrades.deployProxy(ContractFactory)

        await contract.deployed()

        logs && console.log(`The OffchainGroups contract has been deployed to the address: ${contract.address}`)

        return contract
    })
