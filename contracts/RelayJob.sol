pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract RelayJob {
    event JobMessageRelayed(uint256 id);

    event JobMessageRequestCompleted(
        address controller,
        bytes4 selector,
        uint256 id
    );

    struct JobMessageRequest {
        uint256 status;
        uint256 id;
        string metadataURI;
        bytes response;
        bytes4 selector;
        address agent;
    }
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    uint256 public jobCounter;
    mapping(uint256 => JobMessageRequest) public jobs;

    function addJob(
        bytes memory ret,
        bytes4 selector,
        string memory metadataURI
    ) external returns (uint256) {
        jobCounter++;

        jobs[jobCounter] = JobMessageRequest({
            status: 1,
            id: jobCounter,
            metadataURI: metadataURI,
            response: ret,
            selector: selector,
            agent: address(0)
        });

        emit JobMessageRelayed(jobCounter);

        return jobCounter;
    }

    function continueJob(
        uint256 id,
        bytes memory ret,
        bytes4 selector,
        string memory metadataURI
    ) external returns (bool) {
        jobs[id].status = 2;
        jobs[id].metadataURI = metadataURI;
        jobs[id].response = ret;
        jobs[id].selector = selector;

        emit JobMessageRelayed(id);

        return true;
    }

    function hasInit(uint256 id) public returns (bool) {
        return jobs[id].status == 1 || jobs[id].status == 2;
    }

    function exists(uint256 id) public returns (bool) {
        return jobs[id].status > 1;
    }

    function get(uint256 id) public returns (JobMessageRequest memory) {
        return jobs[id];
    }
}
