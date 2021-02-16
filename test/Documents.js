// const assert = require("assert");
const Web3 = require('web3');
const web3 = new Web3();
const BigNumber = require('bignumber.js');
const { ethers } = require('ethers');
const { assert } = require('chai');

contract('Async Request Response Message Gateway', accounts => {
  let dai;
  let owner;
  let registry;
  let relayer;
  let maintainer;
  let testDemoContract;
  let Maintainer = artifacts.require('Maintainer');
  let ActionRouteRegistry = artifacts.require('ActionRouteRegistry');
  let TestDAI = artifacts.require('DAI');
  let StateRelayer = artifacts.require('StateRelayer');
  let TestActionSAContract = artifacts.require('TestActionSAContract');
  let reqResId;
  contract('#SA', () => {
    before(async () => {
      owner = accounts[0];
      dai = await TestDAI.deployed();
      registry = await ActionRouteRegistry.deployed();
      relayer = await StateRelayer.deployed();
      maintainer = await Maintainer.deployed();
      testDemoContract = await TestActionSAContract.deployed();
    });
    describe('when registering an async req/res', () => {
      it('should add it to register for a fee', async () => {
        assert.equal(registry !== null, true);
        // mint 22 DAI
        await dai.mint(
          accounts[0],
          new BigNumber(22 * 1e18)
        );

        // allowance
        await dai.approve(
          maintainer.address
          ,
          new BigNumber(22 * 1e18), {
          from: accounts[0]
        }
        );
        // allowance
        await dai.approve(
          registry.address
          ,
          new BigNumber(22 * 1e18), {
          from: accounts[0]
        }
        );
//        const domain = await testDemoContract.getDomain();
        const controller = testDemoContract.address;
        const messageSelector = web3.eth.abi.encodeFunctionSignature(`propose(string,address,string,string,uint)`);
        const conditions = [
          web3.eth.abi.encodeFunctionSignature(`hasRUC(address,bytes)`),
          web3.eth.abi.encodeFunctionSignature(`hasValidName(address,bytes)`),
        ];
        const conditionStatus = [false, false];
        const whitelist = [];
        // Create controller mapping for messages
        const res = await registry.mapAction(
          controller,
          messageSelector,
          conditions,
          conditionStatus,        
        );

        assert.equal(res.logs[0].args.controller, controller);
      });

    });
    describe('when executing an async req/res message', () => {
      it('should send result to next message', async () => {
        assert.equal(registry !== null, true);

        const controller = testDemoContract.address;
        
        const response = await testDemoContract.propose(
            "Industrias de Firmas Electronicas",
            accounts[2],
            "https://ifesa.ipfs.pa/job_info",
            "https://ifesa.ipfs.pa/company_info",
            new BigNumber(2 * 1e18)
        );
 
        console.log(response.logs[0].args)
        reqResId = 1; // response.logs[0].args.id;
        // const nftAddress = res.logs[0].args.minterAddress;
        // const minter = await DocumentMinter.at(nftAddress);
        // assert.equal(await minter.symbol(), "NOT9APOST");
      });
    });
    describe('when querying an async req/res message conditions', () => {
      it('should update', async () => {
        assert.equal(registry !== null, true);

        const controller = testDemoContract.address;
        const messageSelector = web3.eth.abi.encodeFunctionSignature(`propose(string,address,string,string,uint)`);

        const response = await relayer.executeActionConditions(
          controller,
          messageSelector,
          new BigNumber(reqResId),
        );

        console.log(response);
        // const nftAddress = res.logs[0].args.minterAddress;
        // const minter = await DocumentMinter.at(nftAddress);
        // assert.equal(await minter.symbol(), "NOT9APOST");
      });
    });



  });
});
