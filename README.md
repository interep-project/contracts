<p align="center">
    <h1 align="center">
        InterRep contracts
    </h1>
    <p align="center">InterRep Solidity smart contracts.</p>
</p>

<p align="center">
    <a href="https://github.com/InterRep" target="_blank">
        <img src="https://img.shields.io/badge/project-InterRep-blue.svg?style=flat-square">
    </a>
    <a href="https://github.com/interrep/contracts/blob/main/LICENSE">
        <img alt="Github license" src="https://img.shields.io/github/license/interrep/contracts.svg?style=flat-square">
    </a>
    <a href="https://github.com/interrep/contracts/actions?query=workflow%3Atest">
        <img alt="GitHub Workflow test" src="https://img.shields.io/github/workflow/status/interrep/contracts/test?label=test&style=flat-square&logo=github">
    </a>
    <a href="https://coveralls.io/github/InterRep/contracts">
        <img alt="Coveralls" src="https://img.shields.io/coveralls/github/InterRep/contracts?style=flat-square&logo=coveralls">
    </a>
    <a href="https://eslint.org/" target="_blank">
        <img alt="Linter eslint" src="https://img.shields.io/badge/linter-eslint-8080f2?style=flat-square&logo=eslint">
    </a>
    <a href="https://prettier.io/" target="_blank">
        <img alt="Code style prettier" src="https://img.shields.io/badge/code%20style-prettier-f8bc45?style=flat-square&logo=prettier">
    </a>
    <img alt="Repository top language" src="https://img.shields.io/github/languages/top/InterRep/contracts?style=flat-square">
</p>

<div align="center">
    <h4>
        <a href="https://docs.interrep.link/contributing">
            👥 Contributing
        </a>
        <span>&nbsp;&nbsp;|&nbsp;&nbsp;</span>
        <a href="https://docs.interrep.link/code-of-conduct">
            🤝 Code of conduct
        </a>
        <span>&nbsp;&nbsp;|&nbsp;&nbsp;</span>
        <a href="https://t.me/interrep">
            🗣️ Chat &amp; Support
        </a>
    </h4>
</div>

---

If you want an overwiew of InterRep, read our announcement post: https://jaygraber.medium.com/introducing-interrep-255d3f56682. For more details, please see our [documentation website](https://docs.interrep.link).

⚠️ **Notice**: [interrep.link](https://interrep.link) and [ropsten.interrep.link](https://ropsten.interrep.link) still refer to the old MVP version of interRep. They will soon be updated. You can find an updated version at [kovan.interrep.link](https://kovan.interrep.link) (staging env).

### Deployed contracts

|                           | Kovan                                                                                          | Ropsten                                                                                          | Arbitrum One                                                                                          |
| ------------------------- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| ReputationBadge (Twitter) | [0xe0fC...798d](https://kovan.etherscan.io/address/0xe0fCf7AEDCf8f31F9d6eE4C16Ab89f68d337798d) | [0x2F4d...BC11](https://ropsten.etherscan.io/address/0x2F4d1333337b5C4C47Db5DB3A36eD547a549BC11) | [0x2F4d...BC11](https://explorer.offchainlabs.com/address/0x2F4d1333337b5C4C47Db5DB3A36eD547a549BC11) |
| ReputationBadge (Github)  | [0x1495...2311](https://kovan.etherscan.io/address/0x14958dF52CC76c8f3a919A769006196601012311) |                                                                                                  |                                                                                                       |
| ReputationBadge (Reddit)  | [0x55d2...B4Cf](https://kovan.etherscan.io/address/0x55d2d15631078cC555d06f14fD45bF2A7D86B4Cf) |                                                                                                  |                                                                                                       |
| Groups                    | [0x06d5...Cdcc](https://kovan.etherscan.io/address/0x06d554D4122B694a507459Ce8D93E97d9Dd2Cdcc) |                                                                                                  |                                                                                                       |

---

## Install

Clone this repository and install the dependencies:

```bash
$ git clone https://github.com/InterRep/contracts.git
$ cd contracts
$ yarn # or `npm i`
```

## Usage

Copy the `.env.example` file and rename it `.env`.

### Compile

Compile the smart contracts with Hardhat:

```bash
yarn compile
```

This should generate the TypeChain typings. If you want to generate them manually run:

```bash
yarn typechain
```

### Lint

Lint the Solidity or the TypeScript code:

```bash
yarn lint:sol
yarn lint:ts
# or yarn lint to lint both.
```

And check if the code is well formatted:

```bash
yarn prettier
```

### Test

Run the Mocha tests:

```bash
yarn test
```

### Coverage

Generate the code coverage report:

```bash
yarn coverage
```

### Report Gas

See the gas usage per unit test and average gas per method call:

```bash
REPORT_GAS=true yarn test
```

### Clean

Delete the smart contract artifacts, the coverage reports and the Hardhat cache:

```bash
yarn clean
```

### Deploy

Deploy the contracts:

```bash
yarn deploy:reputation-badge --name "InterRep Twitter Badge" --symbol iTWITT
yarn deploy:groups
```

If you want to deploy contracts in a specific network you can set up the `DEFAULT_NETWORK` variable in your `.env` file with the name of one of our supported networks (hardhat, localhost, ropsten, kovan, arbitrum). Or you can specify it as option:

```bash
yarn deploy:groups --network kovan // Kovan testnet
yarn deploy:groups --network localhost // Local network
```

If you want to deploy the contracts on Ropsten, Kovan or Arbitrum remember to provide a valid private key and an Infura API in your `.env` file.

### Preparing a local network

Run a Hardhat Network in a stand-alone fashion:

```bash
yarn start
```

Deploy mocked contracts:

```bash
yarn mocks --network localhost
```

You can omit `--network localhost` if your `DEFAULT_NETWORK` env variable is equal to `localhost`.
