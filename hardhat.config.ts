import "@nomiclabs/hardhat-etherscan"
import "@nomiclabs/hardhat-waffle"
import "@openzeppelin/hardhat-upgrades"
import "@typechain/hardhat"
import { config as dotenvConfig } from "dotenv"
import "hardhat-gas-reporter"
import { HardhatUserConfig } from "hardhat/config"
import { NetworksUserConfig } from "hardhat/types"
import { resolve } from "path"
import "solidity-coverage"
import "./tasks/accounts"
import "./tasks/clean"
import "./tasks/deploy-offchain-groups"
import "./tasks/deploy-curated-groups"
import "./tasks/deploy-reputation-badge"
import "./tasks/mint"

dotenvConfig({ path: resolve(__dirname, "./.env") })

function getNetworks(): NetworksUserConfig | undefined {
    if (process.env.NODE_ENV === "production") {
        if (!process.env.INFURA_API_KEY) {
            throw new Error("Please set your INFURA_API_KEY in a .env file")
        }

        if (!process.env.BACKEND_PRIVATE_KEY) {
            throw new Error("Please set your BACKEND_PRIVATE_KEY in a .env file")
        }

        const infuraApiKey = process.env.INFURA_API_KEY
        const accounts = [`0x${process.env.BACKEND_PRIVATE_KEY}`]

        return {
            ropsten: {
                url: `https://ropsten.infura.io/v3/${infuraApiKey}`,
                chainId: 3,
                accounts
            },
            kovan: {
                url: `https://kovan.infura.io/v3/${infuraApiKey}`,
                chainId: 42,
                accounts
            },
            arbitrum: {
                url: "https://arb1.arbitrum.io/rpc",
                chainId: 42161,
                accounts
            }
        }
    }
}

const config: HardhatUserConfig = {
    defaultNetwork: process.env.DEFAULT_NETWORK || "hardhat",
    networks: getNetworks(),
    solidity: {
        version: "0.8.0"
    },
    gasReporter: {
        currency: "USD",
        enabled: process.env.REPORT_GAS === "true"
    },
    typechain: {
        outDir: "typechain",
        target: "ethers-v5"
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY
    }
}

export default config
