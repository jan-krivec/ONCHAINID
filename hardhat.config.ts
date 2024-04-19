import "@nomicfoundation/hardhat-toolbox";
import { HardhatUserConfig } from "hardhat/config";
import 'solidity-coverage';
import "@nomiclabs/hardhat-solhint";

import "./tasks/add-claim.task";
import "./tasks/add-key.task";
import "./tasks/deploy-identity.task";
import "./tasks/deploy-proxy.task";
import "./tasks/remove-claim.task";
import "./tasks/remove-key.task";
import "./tasks/revoke.task";

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    ganache: {
      url: "http://127.0.0.1:8454",
      chainId: 1337,
      accounts: ["0xd4d937fe90c767a103aa7cc54ed7dae1f9a501540f212231307049373595ddae"]
    }
  }
};

export default config;
