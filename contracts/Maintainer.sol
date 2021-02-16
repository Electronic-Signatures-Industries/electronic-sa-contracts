pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./RelayJob.sol";
import "./MinLibBytes.sol";
import "./MessageRoute.sol";
import "./Whitelist.sol";
import "./ERC20Interface.sol";
contract Maintainer {
        // Stable coin
    ERC20Interface private stablecoin;

    address private owner;
    RelayJob public relayJob;

    event UserVerified(address worker);
    event AssignmentApplied(uint256 id, address workerAddress);
    event AssignmentGranted(uint256 id, address workerAddress, bool granted);
    event AssignmentResolved(uint256 id, address workerAddress, bool resolved);
    event AssignmentConfirmed(uint256 id, address workerAddress, bool granted);
    event AssignmentPayout(uint256 id, address workerAddress, bool granted);
    event Created(uint256 id);
    event WorkerEnrolled(uint256 id);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    enum WorkerStatus {IDLE, APPLIED_TO, BOOKED, IN_PROGRESS, PENDING_PAYMENT, INACTIVE}

    struct Worker {
        string name;
        address owner;
        bool verified;
        string metadataURI;
        uint256 status;
        address accountsPayable;
    }

    enum AssignmentStatus {
        INIT,
        PENDING,
        IN_PROGRESS,
        REJECTED,
        RESOLVED,
        PAYOUT,
        CANCELLED
    }

    struct Assignment {
        address owner;
        uint256 relayJobId;
        uint256 status;
        uint256 depositAmount;
    }

    // Worker count
    uint256 private workerCount;

    // Assignment count
    uint256 private assignmentCount;

    // Worker accounting

    mapping(address => uint256) private workerAccounting;

    // Total worker accounting

    uint256 private totalWorkerAccounting;

    // Assingment accounting

    mapping(uint256 => uint256) private assignmentAccounting;

    // Total assignment accounting

    uint256 private totalAssignmentAccounting;

    // Assignments
    mapping(uint256 => Assignment) public assignments;

    // Workers
    mapping(address => Worker) public workers;

    // Worker assign to a task
    mapping(address => uint256) public workerTasks;

    constructor(address _relayJob, address tokenAddress) public {
        relayJob = RelayJob(_relayJob);
        stablecoin  = ERC20Interface(tokenAddress);
       
        owner = msg.sender;
    }

    /**
     * @dev Creates an assignment given a new job id
     * @param relayJobId The job id.
     */
    function createAssignmentAndEscrow(uint256 relayJobId, address caller, uint amount)
        public
        payable
        virtual
        returns (uint256)
    {

        // User must have a balance
        require(
            stablecoin.balanceOf(caller) >= 0,
            "Invalid token balance"
        );
        // User must have an allowance
        require(
            stablecoin.allowance(caller, address(this)) >= 0,
            "Invalid token allowance"
        );

        assignments[relayJobId] = Assignment({
            relayJobId: relayJobId,
            status: uint256(AssignmentStatus.INIT),
            depositAmount: amount,
            owner: caller
        });
        assignmentCount++;

        require(
            stablecoin.transferFrom(
                caller,
                address(this), 
                amount),
            "Transfer failed for fee"
        );

        emit Created(relayJobId);
        return relayJobId;
    }

    /**
     * @dev Enroll as worker
     * @param name Worker name
     * @param metadataURI VC or Document hash
     * @param paymentAddress Payment addresss
     */
    function enroll(
        string memory name,
        string memory metadataURI,
        address paymentAddress
    ) public virtual returns (uint256) {
        require(paymentAddress != address(0), "Invalid payment address");
        workers[msg.sender] = Worker({
            name: name,
            accountsPayable: paymentAddress,
            status: uint256(WorkerStatus.IDLE),
            metadataURI: metadataURI,
            verified: false,
            owner: msg.sender
        });
        workerCount++;
        emit WorkerEnrolled(workerCount);
        return workerCount;
    }


    /**
     * @dev set outcome for assignment
     * @param assignmentId Assignment Id
     * @param worker Worker address
     */
    function setOutcomeAssignment(
        uint256 assignmentId,
        address worker,
        bool allow
    ) public virtual returns (bool) {
        // task owner can't be a worker
        require(
            assignments[assignmentId].owner != worker,
            "Task owner cannot be assignment owner"
        );

        // is worker registered
        require(
            workers[worker].verified == true,
            "Worker has not been verified"
        );

        // is assignment available
        require(
            assignments[assignmentId].status ==
                uint256(AssignmentStatus.IN_PROGRESS),
            "Assignment must be pending"
        );

        // is worker available
        require(
            workers[worker].status == uint256(WorkerStatus.BOOKED),
            "Worker must has been applied"
        );

        // is worker not found in current tasks
        require(workerTasks[worker] == assignmentId, "Assignment not found in tasks");

        if (allow) {
        workers[worker].status = uint256(AssignmentStatus.RESOLVED);
        assignments[assignmentId].status = uint256(WorkerStatus.PENDING_PAYMENT);
        emit AssignmentResolved(assignmentId, worker, true);
        } else {
        workers[worker].status = uint256(AssignmentStatus.REJECTED);
        assignments[assignmentId].status = uint256(WorkerStatus.IDLE);
        emit AssignmentResolved(assignmentId, worker, false);
  
        }
        return true;
    }

    function setVerifyUser(
        address worker
    ) public returns(bool) {
        require(owner == msg.sender, "Must be an admin");

        workers[worker].verified = true;
        emit UserVerified(worker);
        return true;
    }
    /**
     * @dev grant assignment
     * @param assignmentId Assignment Id
     * @param worker Worker address
     */
    function grantAssignment(
        uint256 assignmentId,
        address worker,
        bool allow
    ) public virtual returns (bool) {
        // task owner can't be a worker
        require(
            assignments[assignmentId].owner != worker,
            "Task owner cannot be assignment owner"
        );

        // is worker registered
        require(
            workers[worker].verified == true,
            "Worker has not been verified"
        );

        // is assignment available
        require(
            assignments[assignmentId].status ==
                uint256(AssignmentStatus.PENDING),
            "Assignment must be pending"
        );

        // is worker available
        require(
            workers[worker].status == uint256(WorkerStatus.APPLIED_TO),
            "Worker must has been applied"
        );

        // is worker not found in current tasks
        require(workerTasks[worker] == assignmentId, "Assignment not found in tasks");

        if (allow) {
        workers[worker].status = uint256(AssignmentStatus.IN_PROGRESS);
        assignments[assignmentId].status = uint256(WorkerStatus.BOOKED);
        emit AssignmentGranted(assignmentId, worker, true);
        } else {
        workers[worker].status = uint256(AssignmentStatus.REJECTED);
        assignments[assignmentId].status = uint256(WorkerStatus.IDLE);
        emit AssignmentGranted(assignmentId, worker, false);
  
        }
        return true;
    }

    /**
     * @dev apply for assignment
     * @param assignmentId Assignment Id
     * @param worker Worker address
     */
    function applyTo(uint256 assignmentId, address worker)
        public
        virtual
        returns (bool)
    {
        // is worker registered
        require(
            workers[worker].verified == true,
            "Worker has not been verified"
        );

        // is assignment available
        require(
            assignments[assignmentId].status == uint256(AssignmentStatus.INIT),
            "Assignment already in progress"
        );

        // is worker available
        require(
            workers[worker].status == uint256(WorkerStatus.IDLE),
            "Worker already booked or applying"
        );

        // is worker not found in current tasks
        require(workerTasks[worker] == 0, "Assignment already booked");

        // assign worker to task
        workerTasks[worker] = assignmentId;

        workers[worker].status = uint256(AssignmentStatus.PENDING);
        assignments[assignmentId].status = uint256(WorkerStatus.APPLIED_TO);

        emit AssignmentApplied(assignmentId, worker);
        return true;
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     */
    function withdraw(address payable payee) public returns (bool) {
        require(assignments[workerTasks[payee]].depositAmount > 0, "Invalid access");
        uint256 payment = assignments[workerTasks[payee]].depositAmount;
        assignments[workerTasks[payee]].depositAmount = 0;
        require(
            stablecoin.transfer(
                msg.sender,
                payment),
            "Transfer failed for fee"
        );


        emit Withdrawn(payee, payment);

        return true;
    }
}
