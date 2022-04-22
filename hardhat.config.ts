import "@nomiclabs/hardhat-etherscan"
import "@nomiclabs/hardhat-waffle"
import "@typechain/hardhat"
import { config as dotenvConfig } from "dotenv"
import "hardhat-dependency-compiler"
import "hardhat-gas-reporter"
import { HardhatUserConfig } from "hardhat/config"
import { NetworksUserConfig } from "hardhat/types"
import { resolve } from "path"
import "solidity-coverage"
import { config } from "./package.json"
import "./tasks/accounts"
import "./tasks/deploy-interep"
import "./tasks/deploy-verifier"

dotenvConfig({ path: resolve(__dirname, "./.env") })

function getNetworks(): NetworksUserConfig | undefined {
    if (process.env.INFURA_API_KEY && process.env.BACKEND_PRIVATE_KEY) {
        const infuraApiKey = process.env.INFURA_API_KEY
        const accounts = [`0x${process.env.BACKEND_PRIVATE_KEY}`]

        return {
            goerli: {
                url: `https://goerli.infura.io/v3/${infuraApiKey}`,
                chainId: 5,
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

const hardhatConfig: HardhatUserConfig = {
    solidity: config.solidity,
    paths: {
        sources: config.paths.contracts,
        tests: config.paths.tests,
        cache: config.paths.cache,
        artifacts: config.paths.build.contracts
    },
    dependencyCompiler: {
        paths: ["@appliedzkp/semaphore-contracts/base/Verifier.sol"]
    },
    defaultNetwork: process.env.DEFAULT_NETWORK || "hardhat",
    networks: {
        localhost: {
            timeout: 50000
        },
        ...getNetworks()
    },
    gasReporter: {
        currency: "USD",
        enabled: process.env.REPORT_GAS === "true",
        coinmarketcap: process.env.COINMARKETCAP_API_KEY
    },
    typechain: {
        outDir: config.paths.build.typechain,
        target: "ethers-v5"
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY
    }
}

export default hardhatConfig
