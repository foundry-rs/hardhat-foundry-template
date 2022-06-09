# <h1 align="center"> Hardhat x Foundry Template </h1>

**Template repository for getting started quickly with Hardhat and Foundry in one project**

![Github Actions](https://github.com/devanonon/hardhat-foundry-template/workflows/test/badge.svg)

### Getting Started

* Use Foundry:

```bash
forge install
forge test
```

* Use Hardhat:

```bash
npm install
npx hardhat test
```

### Features

* Start an [Anvil](https://book.getfoundry.sh/anvil/index.html) instance with
[hardhat-anvil](https://github.com/foundry-rs/hardhat/tree/develop/packages/hardhat-anvil)

```bash
npx hardhat node
```

* Write / run tests with either Hardhat or Foundry:

```bash
# Foundry Tests
forge test
# or
npm run forge:test

# Hardhat Tests
npx hardhat test
# or
npm run hre:test

# Test both Hardhat and Forge
npm test
```

* Use Hardhat's task framework

```bash
npx hardhat example
```

* Install libraries with Foundry which work with Hardhat.

```bash
forge install rari-capital/solmate # Already in this repo, just an example
```

### Notes

Whenever you install new libraries using Foundry, make sure to update your
`remappings.txt` file by running `forge remappings > remappings.txt`. This is
required because we use `hardhat-preprocessor` and the `remappings.txt` file
to allow Hardhat to resolve libraries you install with Foundry.
