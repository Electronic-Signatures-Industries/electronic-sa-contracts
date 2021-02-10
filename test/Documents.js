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
  let testDemoContract;
  let WFlowRegistry = artifacts.require('WFlowRegistry');
  let TestDAI = artifacts.require('DAI');
  let WStateRelayer = artifacts.require('WStateRelayer');
  let TestActionSAContract = artifacts.require('TestActionSAContract');
  let reqResId;
  contract('#WFlowRegistry', () => {
    before(async () => {
      owner = accounts[0];
      dai = await TestDAI.deployed();
      registry = await WFlowRegistry.deployed();
      relayer = await WStateRelayer.deployed();
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
          registry.address
          ,
          new BigNumber(22 * 1e18), {
          from: accounts[0]
        }
        );

        const controller = testDemoContract.address;
        const messageSelector = web3.eth.abi.encodeFunctionSignature(`propose(address,bytes)`);
        const conditions = [
          web3.eth.abi.encodeFunctionSignature(`hasRUC(address,bytes)`),
          web3.eth.abi.encodeFunctionSignature(`hasValidName(address,bytes)`),
        ];
        const conditionStatus = [false, false];
        const nextMessage = web3.eth.abi.encodeFunctionSignature(
          `register(address,bytes)`);
        // Create controller mapping for messages
        const res = await registry.mapMessageToController(
          controller,
          messageSelector,
          conditions,
          conditionStatus,
          nextMessage
        );

        assert.equal(res.logs[0].args.actionAddress, controller);
      });

    });
    describe('when executing an async req/res message', () => {
      it('should send result to next message', async () => {
        assert.equal(registry !== null, true);

        const controller = testDemoContract.address;
        const messageSelector = web3.eth.abi.encodeFunctionSignature(`propose(address,bytes)`);

        // console.log(res.logs[0]);

        const response = await relayer.executeRequestResponse(
          controller,
          messageSelector,
          ethers.utils.defaultAbiCoder.encode(['string', 'string', 'string'], [
            "IFESA",
            "Paseo Real Casa 29",
            "Informatica/Blockchain"
          ])
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
        const messageSelector = web3.eth.abi.encodeFunctionSignature(`propose(address,bytes)`);

        // console.log(res.logs[0]);

        const response = await relayer.executeJobCondition(
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
