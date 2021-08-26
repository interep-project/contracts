const shell = require("shelljs")

// The environment variables are loaded in hardhat.config.ts.

module.exports = {
    istanbulReporter: ["html", "lcov"],
    onCompileComplete: async function (_config) {
        run("typechain")
    },
    onIstanbulComplete: async function (_config) {
        // We need to do this because solcover generates bespoke artifacts.
        shell.rm("-rf", "./artifacts")
        shell.rm("-rf", "./typechain")
    },
    skipFiles: ["mocks", "test"]
}
