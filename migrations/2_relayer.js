const BigNumber = require('bignumber.js');
const fs = require('fs');
const TestActionSAContract = artifacts.require('TestActionSAContract');
const DAI = artifacts.require('DAI');
const ActionRouteRegistry = artifacts.require('ActionRouteRegistry');
const StateRelayer = artifacts.require('StateRelayer');

const ContractImportBuilder = require('../contract-import-builder');

module.exports = async (deployer, network, accounts) => {
  const builder = new ContractImportBuilder();
  const path = `${__dirname}/../abi-export/main.js`;

  builder.setOutput(path);
  builder.onWrite = (output) => {
    fs.writeFileSync(path, output);
  };
  let dai;
  let daiaddress = ""
  // if (network === "rinkeby") {
  daiaddress = "0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867"
  // }
  // else {

  await deployer.deploy(DAI);
  dai = await DAI.deployed();
  //   daiaddress = dai.address
  // }
  await deployer.deploy(ActionRouteRegistry, dai.address);
  const registry = await ActionRouteRegistry.deployed();
  await registry.setProtocolConfig(new BigNumber(2 * 1e18));
  await deployer.deploy(StateRelayer, registry.address);
  const relayer = await StateRelayer.deployed();

  await deployer.deploy(TestActionSAContract, accounts[0]);
  const demo = await TestActionSAContract.deployed();
  
 // await manager.setProtocolFee(new BigNumber(5 * 1e18));
  builder.addContract(
    'DAI',
    dai,
    daiaddress,
    network
  );

  builder.addContract(
    'ActionRouteRegistry',
    registry,
    registry.address,
    network
  );

  builder.addContract(
    'StateRelayer',
    StateRelayer,
    StateRelayer.address,
    network
  );
  builder.addContract(
    'TestActionSAContract',
    demo,
    demo.address,
  )


};
