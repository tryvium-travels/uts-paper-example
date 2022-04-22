import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "@eth-optimism/plugins/hardhat/compiler"
import "hardhat-gas-reporter";
import "tsconfig-paths/register";

import "@atixlabs/hardhat-time-n-mine";

import { HardhatUserConfig } from "hardhat/config";

import networks from "./hardhat.networks";

const config : HardhatUserConfig = {
  solidity: {
    version: "0.8.13",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000000,
      },
    },
  },
  ovm: {
    solcVersion: "0.8.13",
  },
  networks,
};

export default config;