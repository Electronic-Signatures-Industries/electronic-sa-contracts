pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract RelayJob {
    enum JobStatus {NONE, INIT, CONTINUE, COMPLETED, LIQUIDATED}

    event JobMessageLiquidationRequest(uint256 id);
    event JobMessageRelayed(uint256 id, uint256 status);

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
        uint created;
        uint updated;
        uint ttl;
    }
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    uint256 public jobCounter;
    mapping(uint256 => JobMessageRequest) public jobs;

    /**
     * @dev Creates an assignment given a new job id
     * @param ret response
     * @param selector function name
     * @param metadataURI job metadata
     */
    function addJob(
        bytes memory ret,
        bytes4 selector,
        string memory metadataURI
    ) external returns (uint256) {
        jobCounter++;

        jobs[jobCounter] = JobMessageRequest({
            status: uint256(JobStatus.INIT),
            id: jobCounter,
            metadataURI: metadataURI,
            response: ret,
            selector: selector,
            agent: msg.sender,
            ttl: block.timestamp + 14 days,
            created: block.timestamp,
            updated: 0
        });

        emit JobMessageRelayed(jobCounter, uint256(JobStatus.INIT));

        return jobCounter;
    }

    /**
     * @dev Continues a job
     * @param id The job id
     * @param ret The caller return response
     * @param selector the controller selector
     * @param metadataURI the metadataURI for the job
     */
    function continueJob(
        uint256 id,
        bytes memory ret,
        bytes4 selector,
        string memory metadataURI
    ) external returns (bool) {
        require(msg.sender == jobs[id].agent, "Unauthorized");
        jobs[id].status = uint256(JobStatus.CONTINUE);
        jobs[id].metadataURI = metadataURI;
        jobs[id].response = ret;
        jobs[id].selector = selector;
        jobs[id].updated = block.timestamp;

        emit JobMessageRelayed(jobCounter, uint256(JobStatus.CONTINUE));

        return true;
    }

    /**
     * @dev Completes a job
     * @param id The job id
     */
    function completeJob(
        uint256 id
    ) external returns (bool) {
        require(msg.sender == jobs[id].agent, "Unauthorized");

        jobs[id].status = uint(JobStatus.COMPLETED);
        jobs[id].updated = block.timestamp;

        emit JobMessageRelayed(id, uint(JobStatus.COMPLETED));

        return true;
    }

    /**
     * @dev Liquidate a job
     * @param id The job id
     */
    function liquidateJob(uint256 id) external returns (bool) {
        require(jobs[id].ttl > block.timestamp, "Unauthorized");

        jobs[id].status = uint32(JobStatus.LIQUIDATED);

        emit JobMessageLiquidationRequest(id);

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
