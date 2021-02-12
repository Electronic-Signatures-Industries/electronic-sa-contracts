pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import "./ActionRouteRegistry.sol";
import "./MinLibBytes.sol";
import "./MessageRoute.sol";
import "./Whitelist.sol";

contract Maintainer {

    ActionRouteRegistry public registry;
 
    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private deposits;

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
        uint assignmentValue;
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

    constructor(address wfRegistry) public {
        registry = ActionRouteRegistry(wfRegistry);
    }

    function depositsOf(address worker) public view returns (uint256) {
        return deposits[worker];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     */
    function deposit(uint relayJobId, address payee) public payable virtual  {
        require(registry.)
        uint256 amount = msg.value;
        _deposits[relayJobId] = _deposits[relayJobId] + amount;

        emit Deposited(relayJobId, amount);
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
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.transfer(payment);

        emit Withdrawn(payee, payment);
    }
}