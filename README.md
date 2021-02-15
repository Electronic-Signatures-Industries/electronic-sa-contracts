# electronic-sa-contracts
Electronic SA smart contracts

## development settings

1. `ganache-cli -m "index firm lamp hamster embrace glow width satoshi flat pilot gas worth" -i 10`
2. `truffle compile`
3. `truffle migrate --network development`


## XDV Worker

### ActionRouteRegistry

Register mapped actions or contract functions with `conditions` which are set of prerequisites. The contract implementation must have a set of getters and setters, these setters following a convention which is required to work with dynamic calls in Solidity.

```Solidity
    function setRUC(uint256 id, string memory ruc)
        public onlyWhitelisted(msg.sender, getMethodSig(msg.data))
        propertyChange("ruc", abi.encodePacked(ruc))
        returns (bool)
    {
        require(companies[id].verifiedRuc == false, "RUC already verified");
        companies[id].ruc = ruc;
        companies[id].verifiedRuc = true;
        return true;
    }

    function hasRUC(address caller, bytes calldata params)
        external 
        returns (bool)
    {
        uint256 id = abi.decode(params, (uint256));
        return companies[id].verifiedRuc;
    }
```

These setters additionally uses two modifiers, `propertyChange` which emits an event for the any subscriber waiting for the property change and `onlyWhitelisted` which is an ACL that allows whitelisted callers.

To register an `ActionRoute`, use `mapAction`.

```Javascript
        const controller = testDemoContract.address;
        let messageSelector = web3.eth.abi.encodeFunctionSignature(`propose(string,address,string,string)`);
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
```

### StateRelayer

Manages a smart contract function mapped conditions. Mostly used by agents or bots, these agents must subscribe to `propertyChanged` events or `Messsage*` events, these events allows developers to build message relays between automated conditions, and functions which might be execute by maintainers or other API agents.

To execute a state relayer, call `executeActionConditions`

```Javascript
        // bot: execute conditions on propertyChanged
        let messageSelector = web3.eth.abi.encodeFunctionSignature(`propose(string,address,string,string)`);
        response = await relayer.executeActionConditions(
          controller,
          messageSelector,
          jobId,
        );

        console.log(response.logs);
```

### Maintainer

Takes care of the peer incentives, by creating assignments, managing tasks, enrolling maintainers and any planning between the `service originator` (buyers) and `worker` (seller).

PENDING

### RelayJob

Holds the jobs created to handle the XDV Worker message flow. A job flow lifecycle is similar to an HTTP Async Request Response:

- Initial Request creates a Job Message Request - State 1
- Subsequent async requests keeps alive job by calling `continueJob` - State 2
- Once completed, calls `completeJob` - State 3

Jobs might have `time to live` but in the v0.0.1 jobs are maintain completely by the XDV Worker flow implementation.


### XDV Worker Smart Contract Implementation Sample

```Solidity
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./MinLibBytes.sol";
import "./MessageRoute.sol";
import "./StateRelayer.sol";
import "./Whitelist.sol";
import "./Maintainer.sol";

contract TestActionSAContract is MessageRoute, Whitelist {
    address public owner;
    Maintainer private maintainer;
    StateRelayer private stateRelayer;
    struct SociedadAnonima {
        // Company Name
        string name;
        // Has been verfied
        bool verifiedName;
        // JSON Schema(Name, Activity, Members, Address, Expires, AdditionalLegalDocs, Notary)
        string metadataURI;
        // agent
        address legalResidentAgent;
        string legalResidentAgentDID;
        // RUC
        string ruc;
        uint256 status;
        // Has been verified
        bool verifiedRuc;
        uint256 memberCount;
    }

    struct Member {
        string did;
        address member;
    }

    mapping(uint256 => mapping(uint256 => Member)) public members;

    enum WorkflowState {
        SearchName,
        RequestKYC,
        AddMembers,
        KYCCompleted,
        RegisterCompany, // Name, Members, Capital,
        NotaryStamped,
        Registered,
        OperationsRequested,
        OperationsNoticeCompleted
    }

    event RequestBoardMembersKYC(uint256 indexed id);

    event CompanyAdded(
        string name,
        uint256 indexed id,
        uint256 jobId,
        uint256 escrowedAssignmentId
    );

    event MemberAdded(
        string memberDID,
        address member,
        uint256 companyId,
        uint256 indexed id
    );

    event CompanyRegistered(string name, string ruc, uint256 indexed id);

    uint256 public counter;
    mapping(uint256 => SociedadAnonima) public companies;
    mapping(uint256 => uint) public companyJobs;
    

    constructor(
        address _owner,
        address _maintainer,
        address _stateRelayer
    ) public Whitelist(_owner) {
        maintainer = Maintainer(_maintainer);
        owner = _owner;
        stateRelayer = StateRelayer(_stateRelayer);
    }

    /* Async Message Flow Functions */

    /* Property Getters and Setters */
    // Has Valid Name verifies company name has been completed
    function hasValidName(address caller, bytes calldata params)
        external 
        returns (bool)
    {
        uint256 id = abi.decode(params, (uint256));
        return companies[id].verifiedName;
    }

    // Sets a valid name
    function setValidName(uint256 id, bool ok, bytes4 fnName)
        public onlyWhitelisted(msg.sender, fnName)
        propertyChange("verifiedName", abi.encodePacked(ok))
        returns (bool)
    {
        require(companies[id].verifiedName == false, "Name already verified");
        companies[id].verifiedName = ok;
        return true;
    }

    function setRUC(uint256 id, string memory ruc)
        public onlyWhitelisted(msg.sender, getMethodSig(msg.data))
        propertyChange("ruc", abi.encodePacked(ruc))
        returns (bool)
    {
        require(companies[id].verifiedRuc == false, "RUC already verified");
        companies[id].ruc = ruc;
        companies[id].verifiedRuc = true;
        return true;
    }

    function hasRUC(address caller, bytes calldata params)
        external 
        returns (bool)
    {
        uint256 id = abi.decode(params, (uint256));
        return companies[id].verifiedRuc;
    }

    function hasMemberKYCCompleted(address caller, bytes calldata params)
        external
        returns (bool)
    {
        uint256 id = abi.decode(params, (uint256));
        return (companies[id].status == uint256(WorkflowState.KYCCompleted) &&
        (companies[id].memberCount > 2));
    }

    function hasRegistered(address caller, bytes calldata params)
        external
        returns (bool)
    {
        uint256 id = abi.decode(params, (uint256));
        return companies[id].status == uint256(WorkflowState.Registered);
    }

    function hasNotarized(address caller, bytes calldata params)
        external
        returns (bool)
    {
        uint256 id = abi.decode(params, (uint256));
        return companies[id].status == uint256(WorkflowState.NotaryStamped);
    }

    function setStatus(uint256 id, uint256 status, bytes4 fnName)
        public onlyWhitelisted(msg.sender, fnName)
        propertyChange("status", abi.encodePacked(status))
        returns (bool)
    {
        companies[id].status = status;
        bytes memory params = abi.encodePacked(status);
        return true;
    }

    function hasStatus(address caller, bytes calldata params)
        external
        returns (bool)
    {
        (uint256 id, uint status) = abi.decode(params, (uint256, uint));
        return companies[id].status == status;
    }

    function getDomain() public view returns (bytes32) {
        return
            stateRelayer.getDomainSeparator(
                "TestActionSAContract",
                address(this),
                10,
                "1"
            );
    }

    // Create SA
    function propose(
        string memory name,
        address agent,
        string memory jobMetadataURI,
        string memory metadataURI
    ) public returns (uint256) {

        companies[counter] = SociedadAnonima({
            name: name,
            ruc: "",
            verifiedName: false,
            verifiedRuc: false,
            status: uint256(WorkflowState.SearchName),
            legalResidentAgent: agent,
            legalResidentAgentDID: "",
            metadataURI: metadataURI,
            memberCount: 0
        });
        counter++;

        uint256 jobCounter =
            stateRelayer.addJob(
                abi.encodePacked(counter),
                getMethodSig(msg.data),
                jobMetadataURI
            );

        uint256 escrowid = maintainer.createAssignmentAndEscrow(jobCounter, msg.sender);
        emit CompanyAdded(name, counter, jobCounter, escrowid);

        return counter;
    }

    function addMemberKYC(
        uint256 id,
        uint256 jobId,
        address member,
        string memory did,
        string memory jobMetadataURI
    ) public returns (uint256) {
        require(
            companies[id].status == uint256(WorkflowState.RequestKYC),
            "Invalid state"
        );

        uint256 memberId = companies[id].memberCount;
        members[id][memberId] = Member({did: did, member: member});

        companies[id].memberCount = companies[id].memberCount + 1;

        stateRelayer.continueJob(
            jobId,
            abi.encodePacked(id, memberId),
            getMethodSig(msg.data),
            jobMetadataURI
        );

        emit MemberAdded(did, member, id, memberId);

        return memberId;
    }

    // Client must call setStatus once he enrolls 3 KYC Profiles

    // Register SA
    function register(
        uint256 id,
        uint256 jobId,
        string memory metadataURI,
        string memory jobMetadataURI,
        address legalResidentAgent,
        string memory legalResidentAgentDID
    ) public returns (bool) {

        require(
            companies[id].status == uint256(WorkflowState.AddMembers),
            "Invalid state"
        );

        require(companies[id].memberCount > 2);

        companies[id].legalResidentAgent = legalResidentAgent;
        companies[id].legalResidentAgentDID = legalResidentAgentDID;
        companies[id].metadataURI = metadataURI;
        companies[id].status = uint256(WorkflowState.RegisterCompany);

        stateRelayer.continueJob(
            jobId,
            abi.encodePacked(id, legalResidentAgent, metadataURI),
            getMethodSig(msg.data),
            jobMetadataURI
        );

        return true;
    }

    function notaryStamp(uint256 id, uint jobId, string memory jobMetadataURI) public returns (bool) {

        require(
            companies[id].status == uint256(WorkflowState.RegisterCompany),
            "Invalid state"
        );

        companies[id].status = uint256(WorkflowState.NotaryStamped);

        stateRelayer.continueJob(jobId, abi.encodePacked(id), getMethodSig(msg.data), jobMetadataURI);

        return true;
    }

    function requestKYC(uint id, uint jobId, string memory jobMetadataURI) public returns (bool) {

        companies[id].status = uint256(WorkflowState.RequestKYC);

        emit RequestBoardMembersKYC(id);

        stateRelayer.continueJob(jobId, abi.encodePacked(id), getMethodSig(msg.data), jobMetadataURI);

        return true;
    }

    function completeCompanyRegistration(uint256 id, uint jobId, string memory jobMetadataURI) public returns (bool) {

        require(
            companies[id].status == uint256(WorkflowState.NotaryStamped),
            "Invalid state"
        );

        companies[id].status = uint256(WorkflowState.Registered);

        stateRelayer.continueJob(jobId, abi.encodePacked(id), getMethodSig(msg.data), jobMetadataURI);

        return true;
    }

}

```

### Dapp Integration