import { run } from "hardhat"

async function main(): Promise<void> {
    await run("deploy:reputation-badge", {
        name: "InterRep Twitter Badge",
        symbol: "iTWITTER"
    })
    await run("deploy:reputation-badge", {
        name: "InterRep Github Badge",
        symbol: "iGITHUB"
    })
    await run("deploy:reputation-badge", {
        name: "InterRep Reddit Badge",
        symbol: "iREDDIT"
    })

    const { address } = await run("deploy:groups")
    await run("groups", {
        address,
        depth: 16
    })
}

main()
    .then(() => process.exit(0))
    .catch((error: Error) => {
        console.error(error)
        process.exit(1)
    })
