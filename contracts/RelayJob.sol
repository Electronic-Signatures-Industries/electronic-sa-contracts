pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


contract RelayJob {
    struct MessageRequest {
        uint status;
        uint id;
        bytes response;
        bytes4 selector;
    }

    uint public jobCounter;
    mapping (uint => MessageRequest) public jobs;

    function addJob(
        bytes memory ret,
        bytes4 selector
    ) 
    external returns(uint) {

        jobs[jobCounter] = MessageRequest({
            status: 0,
            id: jobCounter,
            response: ret,
            selector: selector
        });
        jobCounter++;

        return jobCounter;
    }

    function hasInit(
       uint id
    ) 
    public returns(bool) {
        return jobs[id].status == 0;
    }

    function exists(
       uint id
    ) 
    public returns(bool) {
        return jobs[id].selector != bytes4(0);
    }


    function get(
       uint id
    ) 
    public returns(MessageRequest memory) {
        return jobs[id];
    }
}

