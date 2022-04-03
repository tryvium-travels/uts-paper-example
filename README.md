<p align="center">
  <img src="https://res.cloudinary.com/tryvium/image/upload/v1551645701/company/logo-circle.png" height=250 style="margin-left:30px;margin-right:30px;"/> 
</p>

![GitHub](https://img.shields.io/github/license/tryvium-travels/uts-paper-example?style=flat-square)
![Twitter Follow](https://img.shields.io/twitter/follow/tryviumtravels?style=social)

# Tryvium Universal Token Swapper

> **WARNING**: This repository is in early-alpha version, highly unstable and is not definitely ready for production use.

The Tryvium Universal Token Swapper, a new way to transform swaps into payments.

# Usage

Initialize the `ETH_INFURA_RPC_URL` variable with a valid infura RPC node URL to enable tests.

```
export ETH_INFURA_RPC_URL="<your-personal-infura-rpc-url>"
```

Copy the contracts in your project. After that you can refer to them in your contract like this:

``` solidity
pragma solidity ^0.8.7;

import "ITokenSwapper.sol";

contract MultiPayerExample {
  swapper ITokenSwapper private immutable;

  // and so on...
}
```

Or extend the functionality of the current swappers like this:

``` solidity
pragma solidity ^0.8.7;

import "ITokenSwapper.sol";

contract ExtendedTokenSwapper is ITokenSwapper {
  // implement the ITokenSwapper virtual methods
}
```

that's it.

## Need some test mocks for your dex routers ?

You can use ours !!! Check the contract we have in the [`contracts/test`](./contracts/test) folder.

_____

### APPENDIX: How to build locally

First of all you need to install the dependencies

``` bash
yarn install
```

Then you can add your solidity smart contracts to the [`contracts`](./contracts) directory and the contract tests to the [`test`](./test) directory.

Finally, you can build your contracts using

``` bash
yarn build
```

and you can test them using [`hardhat`](https://hardhat.org/guides/waffle-testing.html).

``` bash
yarn hardhat test
```

You can also run mythril security tests using the command:

``` bash
yarn run mythril-security-checks
# or simply
yarn mythril-security-checks
```

This project is powered by [`waffle`](https://getwaffle.io), [`Typescript`](https://www.typescriptlang.org) and [`hardhat`](https://hardhat.org).

Please, see the details of the scripts in [`package.json` file](package.json).

### Running tests in VSCode UI

> The content comes from [this page](https://hardhat.org/guides/vscode-tests.html).

You can run your tests from [Visual Studio Code](https://code.visualstudio.com) by using one of its Mocha integration extensions. We recommend using [Mocha Test Explorer](https://marketplace.visualstudio.com/items?itemName=hbenl.vscode-mocha-test-adapter).

##### Making TypeScript tests work

Running tests written in TypeScript from [Visual Studio Code](https://code.visualstudio.com) requires you to set the vscode option `"mochaExplorer.files"` to `"test/**/*.{j,t}s"`.

Or simply use the `vscode/settings.json` file from this repository.
