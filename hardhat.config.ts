import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@openzeppelin/hardhat-upgrades";
import "@typechain/hardhat";
import { config as dotenvConfig } from "dotenv";
import "hardhat-gas-reporter";
import { HardhatUserConfig } from "hardhat/config";
import { NetworksUserConfig } from "hardhat/types";
import { resolve } from "path";
import "solidity-coverage";
import "./tasks/accounts";
import "./tasks/clean";

dotenvConfig({ path: resolve(__dirname, "./.env") });

function getNetworks(): NetworksUserConfig | undefined {
  if (process.env.NODE_ENV === "production") {
    const infuraApiKey = process.env.INFURA_API_KEY;
    const mnemonic = process.env.MNEMONIC;

    if (!infuraApiKey) {
      throw new Error("Please set your INFURA_API_KEY in a .env file");
    }

    if (!mnemonic) {
      throw new Error("Please set MNEMONIC in a .env file");
    }

    return {
      ropsten: {
        url: "https://ropsten.infura.io/v3/" + infuraApiKey,
        chainId: 3,
        accounts: {
          count: 10,
          mnemonic,
        },
      },
      kovan: {
        url: "https://kovan.infura.io/v3/" + infuraApiKey,
        chainId: 42,
        accounts: {
          count: 10,
          mnemonic,
        },
      },
      arbitrum: {
        url: "https://arb1.arbitrum.io/rpc",
        chainId: 42161,
        accounts: {
          count: 10,
          mnemonic,
        },
      },
    };
  }
}

const config: HardhatUserConfig = {
  defaultNetwork: process.env.DEFAULT_NETWORK || "hardhat",
  networks: getNetworks(),
  solidity: {
    version: "0.8.0",
  },
  gasReporter: {
    currency: "USD",
    enabled: process.env.REPORT_GAS ? true : false,
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
