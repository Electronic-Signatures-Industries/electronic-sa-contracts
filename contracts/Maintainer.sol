pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./RelayJob.sol";
import "./MinLibBytes.sol";
import "./MessageRoute.sol";
import "./Whitelist.sol";

contract Maintainer {

    address public owner;
    RelayJob public relayJob;
 
    event Created(uint id);
    event WorkerEnrolled(uint id);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    enum WorkerStatus {
        IDLE,
        BOOKED,
        IN_PROGRESS,
        OFF,
        INACTIVE
    }
    
    struct Worker {
       string name;
        bool verified;
        string metadataURI;
        uint status;
        address accountsPayable;
    }

    enum AssignmentStatus {
        INIT,
        PENDING,
        IN_PROGRESS,
        REJECTED,
        RESOLVED,
        CANCELLED
    }

    struct Assignment {
        string name;
        uint relayJobId;
        uint status;
        uint depositAmount;
    }

    // Worker count


    uint public workerCount;

    // Assignment count

    uint public assignmentCount;

    // Worker accounting

    mapping (address => uint) public workerAccounting;

    // Total worker accounting

    uint public totalWorkerAccounting;

    // Assingment accounting

    mapping (uint => uint) public assignmentAccounting;

    // Total assignment accounting

    uint public totalAssignmentAccounting;

    // Assignments
    mapping (uint => Assignment) public assignments;

    // Workers
    mapping (address => Worker) public workers;

    // Worker assign to a task
    mapping (address => Assignment) public workerTasks;

    constructor(address _relayJob) public {
        relayJob = RelayJob(_relayJob);
        owner = msg.sender;
    }

    function depositsOf(address worker) public view returns (uint256) {
        return deposits[worker];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     */
    function createAssignmentAndEscrow(
        uint relayJobId,
        string memory name
    ) public payable virtual  returns(uint) {
       require(relayJob.exists(relayJobId), "No job id found");
       
        uint256 amount = msg.value;
        assignments[assignmentCount] = Assignment({
            name: name,
            relayJobId: relayJobId,
            status: uint(AssignmentStatus.INIT),
            depositAmount: msg.value
        });
        assignmentCount++;
        emit Created(assignmentCount);
        return assignmentCount;
    }

    function enrollAsWorker(
        string memory name,
        string memory metadataURI,
        address paymentAddress
    ) public virtual  returns(uint) {
       
        workers[workerCount] = Worker({
            name: name,
            paymentAddress: paymentAddress,
            status: uint(WorkerStatus.IDLE),
            metadataURI: metadataURI
        });
        workerCount++;
        emit WorkerEnrolled(workerCount);
        return workerCount;
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
    function withdraw(address payable payee) public returns(bool) {
        require(workerTasks[payee].depositAmount > 0, "Invalid access");
        uint payment = workerTasks[payee].depositAmount;
        workerTasks[payee].depositAmount] = 0;
        payee.transfer(payment);

        emit Withdrawn(payee, payment);
    }
}