import { run } from "hardhat"

async function main() {
    const { address: verifierAddress } = await run("deploy:verifier", { logs: false })
    const { address: interepAddress } = await run("deploy:interep", {
        logs: false,
        verifiers: [{ merkleTreeDepth: 20, contractAddress: verifierAddress }]
    })

    console.log(`Interep contract has been deployed to: ${interepAddress}`)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
