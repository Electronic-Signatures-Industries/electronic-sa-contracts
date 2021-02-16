const BigNumber = require('bignumber.js');
const fs = require('fs');
const TestActionSAContract = artifacts.require('TestActionSAContract');
const DAI = artifacts.require('DAI');
const ActionRouteRegistry = artifacts.require('ActionRouteRegistry');
const StateRelayer = artifacts.require('StateRelayer');
const Maintainer = artifacts.require('Maintainer');
const RelayJob = artifacts.require('RelayJob');


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
  // daiaddress = "0xec5dcb5dbf4b114c9d0f65bccab49ec54f6a0867"
  // }
  // else {

  await deployer.deploy(DAI);
  dai = await DAI.deployed();
  //   daiaddress = dai.address
  // }

  // ActionRouteRegistry(erc20Token)
  await deployer.deploy(ActionRouteRegistry, dai.address);
  const registry = await ActionRouteRegistry.deployed();
  
  // RelayJob()
  await deployer.deploy(RelayJob);
  const relayJob = await RelayJob.deployed();
  
  // StateRelayer(registry, relayJob)
  await deployer.deploy(StateRelayer, registry.address, relayJob.address);
  const stateRelayer = await StateRelayer.deployed();

  // Maintainer(relayJob)
  await deployer.deploy(Maintainer, relayJob.address, dai.address);
  const maintainer = await Maintainer.deployed();

  // Smart Contract XDV Business Events contract implementation(maintainer, stateRelayer)
  await deployer.deploy(TestActionSAContract, accounts[0], maintainer.address, relayJob.address);
  const saMaker = await TestActionSAContract.deployed();

  await registry.setProtocolFee(new BigNumber(2 * 1e18));
  
  builder.addContract(
    'DAI',
    dai,
    daiaddress,
    network
  );


  builder.addContract(
    'RelayJob',
    relayJob,
    relayJob.address,
    network
  );


  builder.addContract(
    'Maintainer',
    maintainer,
    maintainer.address,
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
    saMaker,
    saMaker.address,
  )


};
