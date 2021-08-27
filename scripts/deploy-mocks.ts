import { run } from "hardhat"

async function main(): Promise<void> {
    await run("deploy:reputation-badge", {
        name: "InterRep Twitter Badge",
        symbol: "iTWITT"
    })
    await run("deploy:interrep-groups")
}

main()
    .then(() => process.exit(0))
    .catch((error: Error) => {
        console.error(error)
        process.exit(1)
    })
