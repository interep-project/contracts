import { Contract } from "ethers"
import { task, types } from "hardhat/config"

task("deploy:reputation-badge", "Deploy a ReputationBadge contract")
    .addParam("name", "The name of the token")
    .addParam("symbol", "The symbol of the token")
    .addOptionalParam<boolean>("logs", "Print the logs", true, types.boolean)
    .setAction(async ({ name, symbol, logs }, { ethers, upgrades }): Promise<Contract> => {
        const [signer] = await ethers.getSigners()
        const ContractFactory = await ethers.getContractFactory("ReputationBadge")

        // Unfortunately the first signer is used to deploy and there is no option to change that
        // See https://github.com/OpenZeppelin/openzeppelin-upgrades/issues/271
        const contract = await upgrades.deployProxy(ContractFactory, [name, symbol, signer.address])

        await contract.deployed()

        logs && console.log(`The ReputationBadge contract has been deployed to the address: ${contract.address}`)

        return contract
    })
