import { task } from "hardhat/config"

task("deploy:reputation-badge", "Deploy a ReputationBadge contract")
    .addParam("name", "The name of the token")
    .addParam("symbol", "The symbol of the token")
    .setAction(async ({ name, symbol }, { ethers, upgrades }) => {
        const [signer] = await ethers.getSigners()
        const ContractFactory = await ethers.getContractFactory("ReputationBadge")

        // Unfortunately the first signer is used to deploy and there is no option to change that
        // See https://github.com/OpenZeppelin/openzeppelin-upgrades/issues/271
        const contract = await upgrades.deployProxy(ContractFactory, [name, symbol, signer.address])

        await contract.deployed()

        console.log(`The ReputationBadge contract has been deployed to the address: ${contract.address}`)
    })
