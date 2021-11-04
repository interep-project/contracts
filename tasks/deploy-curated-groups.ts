import { task, types } from "hardhat/config"
import { poseidonContract } from "circomlibjs"
import { Contract } from "ethers"

task("deploy:curated-groups", "Deploy a CuratedGroups contract")
    .addOptionalParam<boolean>("logs", "Print the logs", true, types.boolean)
    .setAction(async ({ logs }, { ethers, upgrades }): Promise<Contract> => {
        const poseidonABI = poseidonContract.generateABI(2)
        const poseidonBytecode = poseidonContract.createCode(2)

        const [signer] = await ethers.getSigners()

        const PoseidonLibFactory = new ethers.ContractFactory(poseidonABI, poseidonBytecode, signer)
        const poseidonLib = await PoseidonLibFactory.deploy()

        await poseidonLib.deployed()

        const BinaryTreeLibFactory = await ethers.getContractFactory("BinaryTree", {
            libraries: {
                Hash: poseidonLib.address
            }
        })
        const binaryTreeLib = await BinaryTreeLibFactory.deploy()

        const ContractFactory = await ethers.getContractFactory("CuratedGroups", {
            libraries: {
                BinaryTree: binaryTreeLib.address
            }
        })
        const contract = await upgrades.deployProxy(ContractFactory, {
            unsafeAllowLinkedLibraries: true
        })

        await contract.deployed()

        logs && console.log(`The CuratedGroups contract has been deployed to the address: ${contract.address}`)

        return contract
    })
