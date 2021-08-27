import { task } from "hardhat/config"

task("deploy:interrep-groups", "Deploy an InterRepGroups contract").setAction(async (args, { ethers, upgrades }) => {
    const InterRepGroupsFactory = await ethers.getContractFactory("InterRepGroups")

    const interRepGroups = await upgrades.deployProxy(InterRepGroupsFactory)

    await interRepGroups.deployed()

    console.log(`The InterRepGroups contract has been deployed to the address: ${interRepGroups.address}`)
})
