// const assert = require("assert");
const Web3 = require('web3');
const web3 = new Web3();
const BigNumber = require('bignumber.js');
const { ethers } = require('ethers');
const { assert } = require('chai');

contract('SA', accounts => {
  let dai;
  let owner;
  let registry;
  let relayer;
  let testDemoContract;
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
        const domain = await registry.getDomainSeparator(
          'TestActionSAContract',
          testDemoContract.address,
          10,
          '1'
        );
        const controller = testDemoContract.address;
        let messageSelector = web3.eth.abi.encodeFunctionSignature(`propose(address,bytes)`);
        let conditions = [
          web3.eth.abi.encodeFunctionSignature(`hasValidName(address,bytes)`),
        ];
        let conditionStatus = [false];
        let whitelist = [];
        // Create controller mapping for messages
        let res = await registry.mapAction(
          domain,
          controller,
          messageSelector,
          conditions,
          conditionStatus,
          whitelist
        );

        assert.equal(res.logs[0].args.controller, controller);

        messageSelector = web3.eth.abi.encodeFunctionSignature(`requestKYC(address,bytes)`);
        conditions = [];
        conditionStatus = [];
        whitelist = [accounts[0], accounts[1], accounts[2]];
        // Create controller mapping for messages
        res = await registry.mapAction(
          domain,
          controller,
          messageSelector,
          conditions,
          conditionStatus,
          whitelist
        );

        assert.equal(res.logs[0].args.controller, controller);

        messageSelector = web3.eth.abi.encodeFunctionSignature(`addMemberKYC(address,bytes)`);
        conditions = [
          web3.eth.abi.encodeFunctionSignature(`hasMemberKYCCompleted(address,bytes)`),
        ];
        conditionStatus = [false];
        whitelist = [accounts[0], accounts[1], accounts[2]];
        // Create controller mapping for messages
        res = await registry.mapAction(
          domain,
          controller,
          messageSelector,
          conditions,
          conditionStatus,
          whitelist
        );

        assert.equal(res.logs[0].args.controller, controller);


        messageSelector = web3.eth.abi.encodeFunctionSignature(`register(address,bytes)`);
        conditions = [
          web3.eth.abi.encodeFunctionSignature(`hasRegistered(address,bytes)`),
        ];
        conditionStatus = [false];
        whitelist = [accounts[0], accounts[1], accounts[2]];
        // Create controller mapping for messages
        res = await registry.mapAction(
          domain,
          controller,
          messageSelector,
          conditions,
          conditionStatus,
          whitelist
        );

        assert.equal(res.logs[0].args.controller, controller);


        messageSelector = web3.eth.abi.encodeFunctionSignature(`notaryStamp(address,bytes)`);
        conditions = [
          web3.eth.abi.encodeFunctionSignature(`hasNotarized(address,bytes)`),
        ];
        conditionStatus = [false];
        whitelist = [accounts[0], accounts[1], accounts[2]];
        // Create controller mapping for messages
        res = await registry.mapAction(
          domain,
          controller,
          messageSelector,
          conditions,
          conditionStatus,
          whitelist
        );

        assert.equal(res.logs[0].args.controller, controller);

        // let the owner be the only able to update status
        await registry.setUserWhitelist(
          accounts[0],
          web3.eth.abi.encodeFunctionSignature(`setUserWhitelist(address,bytes4,bool)`),
          true
        );
        await registry.setUserWhitelist(
          accounts[1],
          web3.eth.abi.encodeFunctionSignature(`setValidName(uint,bool)`),
          true
        );
      });

    });
    describe('when executing a complete flow', () => {
      it('should be successfully completedd', async () => {
        assert.equal(registry !== null, true);

        const controller = testDemoContract.address;
        const messageSelector = web3.eth.abi.encodeFunctionSignature(`propose(address,bytes)`);

        // console.log(res.logs[0]);
        const domain = await registry.getDomainSeparator(
          'TestActionSAContract',
          testDemoContract.address,
          10,
          '1'
        );

        // Propose
        let response = await relayer.executeAction(
          domain,
          messageSelector,
          ethers.utils.defaultAbiCoder.encode(['string', 'string'], [
            "Industrias de Firmas Electronicas",
            "https  ://ifesa.ipfs.pa/",
          ])
        );
        console.log(response.logs[1].args.id);
        // Set name has been verified offchain
        response = await testDemoContract.setValidName(
          response.logs[1].args.id,
          true,{
            from: accounts[1]
          }
        );

        reqResId = response.logs[1].args.id;
        
        // execute conditions
        response = await relayer.executeActionConditions(
          domain,
          messageSelector,
          new BigNumber(reqResId),
        );

        console.log(response.logs);
   
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
        const domain = await registry.getDomainSeparator(
          'TestActionSAContract',
          testDemoContract.address,
          10,
          '1'
        );
        const response = await relayer.executeActionConditions(
          domain,
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
