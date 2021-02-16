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
          new BigNumber(2200 * 1e18)
        );

        // allowance
        await dai.approve(
          registry.address
          ,
          new BigNumber(22 * 1e18), {
          from: accounts[0]
        }
        );

        // allowance
        await dai.approve(
          maintainer.address
          ,
          new BigNumber(22 * 1e18), {
          from: accounts[0]
        }
        );

        const controller = testDemoContract.address;
        let messageSelector = web3.eth.abi.encodeFunctionSignature(`propose(string,address,string,string,uint)`);
        let conditions = [
          web3.eth.abi.encodeFunctionSignature(`hasValidName(address,bytes)`),
        ];
        let conditionStatus = [false];
        // Create controller mapping for messages
        let res = await registry.mapAction(
          controller,
          messageSelector,
          conditions,
          conditionStatus,
        );

        assert.equal(res.logs[0].args.controller, controller);

        messageSelector = web3.eth.abi.encodeFunctionSignature(`requestKYC(uint,uint,string)`);
        conditions = [];
        conditionStatus = [];
        // Create controller mapping for messages
        res = await registry.mapAction(
          controller,
          messageSelector,
          conditions,
          conditionStatus,
        );

        assert.equal(res.logs[0].args.controller, controller);

        messageSelector = web3.eth.abi.encodeFunctionSignature(`addMemberKYC(uint,uint,string,address,address)`);
        conditions = [
          web3.eth.abi.encodeFunctionSignature(`hasMemberKYCCompleted(address,bytes)`),
        ];
        conditionStatus = [false];
        // Create controller mapping for messages
        res = await registry.mapAction(

          controller,
          messageSelector,
          conditions,
          conditionStatus,
        );

        assert.equal(res.logs[0].args.controller, controller);


        messageSelector = web3.eth.abi.encodeFunctionSignature(`register(uint,uint,string,string,address,string)`);
        conditions = [
          web3.eth.abi.encodeFunctionSignature(`hasRegistered(address,bytes)`),
        ];
        conditionStatus = [false];
        // Create controller mapping for messages
        res = await registry.mapAction(

          controller,
          messageSelector,
          conditions,
          conditionStatus,
        );

        assert.equal(res.logs[0].args.controller, controller);


        messageSelector = web3.eth.abi.encodeFunctionSignature(`notaryStamp(uint,uint,string)`);
        conditions = [
          web3.eth.abi.encodeFunctionSignature(`hasNotarized(address,bytes)`),
        ];
        conditionStatus = [false];
        // Create controller mapping for messages
        res = await registry.mapAction(

          controller,
          messageSelector,
          conditions,
          conditionStatus,
        );

        assert.equal(res.logs[0].args.controller, controller);
      });

    });
    describe('when executing a complete flow', () => {
      it('should be successfully completedd', async () => {
        assert.equal(registry !== null, true);

        const controller = testDemoContract.address;

        // ofertante: Propose,  pay and create assignment
        let response = await testDemoContract.propose(
          "Industrias de Firmas Electronicas",
          accounts[2],
          "https://ifesa.ipfs.pa/job_info",
          "https://ifesa.ipfs.pa/company_info",
          new BigNumber(2 * 1e18)
        );

        let { name, id, jobId } = response.logs[0].args;

        // maintainer: enroll
        await maintainer.enroll(
          "Rogelio Morrell",
          "https://ifesa.ipfs.pa/ipfs/did_user_1",
          accounts[1]
        );

        // management: add verified user
        await maintainer.setVerifyUser(
          accounts[1], {
          from: accounts[0]
        }
        );

        // maintainer: apply to
        const appliedTo = await maintainer.applyTo(
          jobId,
          accounts[1], {
          from: accounts[1]
        }
        );

        // ofertante: review applications by querying AssignmentApplied
        assert.equal(appliedTo.logs[0].args.id.toNumber(), id.toNumber());
        assert.equal(appliedTo.logs[0].args.workerAddress, accounts[1]);
        // ofertante: grant assignment  and whitelist

        await testDemoContract.setUserWhitelist(
          accounts[1],
          web3.eth.abi.encodeFunctionSignature(`setValidName(uint,bool,bytes4)`),
          true, {
          from: accounts[0]
        }
        );

        await maintainer.grantAssignment(
          appliedTo.logs[0].args.id,
          appliedTo.logs[0].args.workerAddress,
          true
        );

        // mantainer: Set name has been verified offchain
        response = await testDemoContract.setValidName(
          id,
          true,
          web3.eth.abi.encodeFunctionSignature(`setValidName(uint,bool,bytes4)`), {
          from: accounts[1]
        }
        );

        // reqResId = response.logs[1].args.id;

        // bot: execute conditions on propertyChanged
        let messageSelector = web3.eth.abi.encodeFunctionSignature(`propose(string,address,string,string,uint)`);
        response = await relayer.executeActionConditions(
          controller,
          messageSelector,
          jobId,
        );

        console.log(response.logs);

        // ofertante: listen for MessageRequestCompleted
        // ofertante: execute next
        response = await testDemoContract.requestKYC(
          id,
          jobId,
          "https://ifesa.ipfs.pa/job_info",
        );

        response = await testDemoContract.addMemberKYC(
          id,
          jobId,
          accounts[0],
          "https://ifesa.ipfs.pa/did",
          "https://ifesa.ipfs.pa/job_info",
        );

        response = await testDemoContract.addMemberKYC(
          id,
          jobId,
          accounts[1],
          "https://ifesa.ipfs.pa/did",
          "https://ifesa.ipfs.pa/job_info",
        );

        response = await testDemoContract.addMemberKYC(
          id,
          jobId,
          accounts[2],
          "https://ifesa.ipfs.pa/did",
          "https://ifesa.ipfs.pa/job_info",
        );

        // mantainer: Set status

        await testDemoContract.setUserWhitelist(
          accounts[1],
          web3.eth.abi.encodeFunctionSignature(`setStatus(uint,uint,bytes4)`),
          true, {
          from: accounts[0]
        }
        );
        response = await testDemoContract.setStatus(
          id,
          3,
          web3.eth.abi.encodeFunctionSignature(`setStatus(uint,uint,bytes4)`), {
          from: accounts[1]
        }
        );


        // bot: execute conditions on propertyChanged
        messageSelector = web3.eth.abi.encodeFunctionSignature(`addMemberKYC(uint,uint,string,address,address)`);
        response = await relayer.executeActionConditions(
          controller,
          messageSelector,
          jobId,
        );


        // const nftAddress = res.logs[0].args.minterAddress;
        // const minter = await DocumentMinter.at(nftAddress);
        // assert.equal(await minter.symbol(), "NOT9APOST");
      });
    });
    xdescribe('when querying an async req/res message conditions', () => {
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
