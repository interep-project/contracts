import { task, types } from "hardhat/config"
// eslint-disable-next-line camelcase
import { poseidon_gencontract as poseidonContract } from "circomlibjs"
import { Contract } from "ethers"

task("deploy:groups", "Deploy a Groups contract")
    .addOptionalParam<boolean>("logs", "Print the logs", true, types.boolean)
    .setAction(async ({ logs }, { ethers, upgrades }): Promise<Contract> => {
        const poseidonABI = poseidonContract.generateABI(2)
        const poseidonBytecode = poseidonContract.createCode(2)

        const [signer] = await ethers.getSigners()

        const PoseidonLibFactory = new ethers.ContractFactory(poseidonABI, poseidonBytecode, signer)
        const poseidonLib = await PoseidonLibFactory.deploy()

        await poseidonLib.deployed()

        logs && console.log(`Poseidon library has been deployed to: ${poseidonLib.address}`)

        const IncrementalTreeLibFactory = await ethers.getContractFactory("IncrementalTree", {
            libraries: {
                Hash: poseidonLib.address
            }
        })
        const incrementalTreeLib = await IncrementalTreeLibFactory.deploy()

        await incrementalTreeLib.deployed()

        logs && console.log(`IncrementalTree library has been deployed to: ${incrementalTreeLib.address}`)

        const ContractFactory = await ethers.getContractFactory("Groups", {
            libraries: {
                IncrementalTree: incrementalTreeLib.address
            }
        })
        const contract = await upgrades.deployProxy(ContractFactory, {
            unsafeAllowLinkedLibraries: true
        })

        await contract.deployed()

        logs && console.log(`Groups contract has been deployed to: ${contract.address}`)

        return contract
    })
