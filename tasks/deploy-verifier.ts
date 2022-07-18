import { Contract } from "ethers"
import { task, types } from "hardhat/config"

task("deploy:verifier", "Deploy a Verifier20 contract")
    .addOptionalParam<boolean>("logs", "Print the logs", true, types.boolean)
    .setAction(async ({ logs }, { ethers }): Promise<Contract> => {
        const ContractFactory = await ethers.getContractFactory("Verifier20")

        const contract = await ContractFactory.deploy()

        await contract.deployed()

        logs && console.log(`Verifier20 contract has been deployed to: ${contract.address}`)

        return contract
    })
