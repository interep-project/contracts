import { Contract } from "ethers"
import { task, types } from "hardhat/config"

task("deploy:interep", "Deploy an Interep contract")
    .addOptionalParam<boolean>("logs", "Print the logs", true, types.boolean)
    .addParam("verifiers", "Tree depths and verifier addresses", undefined, types.json)
    .setAction(async ({ logs, verifiers }, { ethers }): Promise<Contract> => {
        const ContractFactory = await ethers.getContractFactory("Interep")

        const contract = await ContractFactory.deploy(verifiers)

        await contract.deployed()

        logs && console.log(`Interep contract has been deployed to: ${contract.address}`)

        return contract
    })
