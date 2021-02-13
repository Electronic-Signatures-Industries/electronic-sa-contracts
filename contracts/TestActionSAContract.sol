pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./MinLibBytes.sol";
import "./MessageRoute.sol";
import "./StateRelayer.sol";
import "./Utils.sol";
import "./Maintainer.sol";

contract TestActionSAContract is MessageRoute, Utils {
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

    event CompanyAdded(string name, uint256 indexed id);

    event MemberAdded(
        string memberDID,
        address member,
        uint256 companyId,
        uint256 indexed id
    );

    event CompanyRegistered(string name, string ruc, uint256 indexed id);

    uint256 public counter;
    mapping(uint256 => SociedadAnonima) public companies;

    constructor(
        address _owner,
        address _maintainer,
        address _stateRelayer
    ) {
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
    function setValidName(uint256 id, bool ok)
        public
        propertyChange("verifiedName", abi.encodePacked(ok))
        returns (bool)
    {
        require(companies[id].verifiedName == false, "Name already verified");
        companies[id].verifiedName = ok;
        return true;
    }

    function setRUC(uint256 id, string memory ruc)
        public
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
        return companies[id].status == uint256(WorkflowState.KYCCompleted);
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

    function setStatus(uint256 id, uint256 status)
        public
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
        uint256 id = abi.decode(params, (uint256));
        return companies[id].status == id;
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
        string memory metadataURI
    ) public returns (uint256) {
        stateRelayer.validateState(getDomain(), getMethodSig(msg.data));

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
                getMethodSig(msg.data)
            );

        emit MessageRelayed(jobCounter);

        emit CompanyAdded(name, counter);

        return counter;
    }

    function addMemberKYC(
        uint256 id,
        address member,
        string memory did
    ) public returns (uint256) {
        stateRelayer.validateState(getDomain(), getMethodSig(msg.data));
        require(
            companies[id].status == uint256(WorkflowState.RequestKYC),
            "Invalid state"
        );

        uint256 memberId = companies[id].memberCount;
        members[id][memberId] = Member({did: did, member: member});

        companies[id].memberCount = companies[id].memberCount + 1;

        uint256 jobCounter =
            stateRelayer.addJob(
                abi.encodePacked(counter),
                getMethodSig(msg.data)
            );

        emit MessageRelayed(jobCounter);

        emit MemberAdded(did, member, id, memberId);

        return memberId;
    }

    // Client must call setStatus once he enrolls 3 KYC Profiles

    // Register SA
    function register(
        uint256 id,
        string memory metadataURI,
        address legalResidentAgent,
        string memory legalResidentAgentDID
    ) public returns (bool) {
        stateRelayer.validateState(getDomain(), getMethodSig(msg.data));

        require(
            companies[id].status == uint256(WorkflowState.AddMembers),
            "Invalid state"
        );

        companies[id].legalResidentAgent = legalResidentAgent;
        companies[id].legalResidentAgentDID = legalResidentAgentDID;
        companies[id].metadataURI = metadataURI;
        companies[id].status = uint256(WorkflowState.RegisterCompany);

        uint256 jobCounter =
            stateRelayer.addJob(
                abi.encodePacked(counter),
                getMethodSig(msg.data)
            );

        emit MessageRelayed(jobCounter);

        return true;
    }

    function notaryStamp(uint256 id) public returns (bool) {
        stateRelayer.validateState(getDomain(), getMethodSig(msg.data));

        require(
            companies[id].status == uint256(WorkflowState.RegisterCompany),
            "Invalid state"
        );

        companies[id].status = uint256(WorkflowState.NotaryStamped);

        uint256 jobCounter =
            stateRelayer.addJob(
                abi.encodePacked(counter),
                getMethodSig(msg.data)
            );

        emit MessageRelayed(jobCounter);

        return true;
    }

    function requestKYC(uint256 id) public returns (bool) {
        stateRelayer.validateState(getDomain(), getMethodSig(msg.data));

        companies[id].status = uint256(WorkflowState.RequestKYC);

        emit RequestBoardMembersKYC(id);

        return true;
    }

    function completeCompanyRegistration(uint256 id) public returns (bool) {
        stateRelayer.validateState(getDomain(), getMethodSig(msg.data));

        require(
            companies[id].status == uint256(WorkflowState.NotaryStamped),
            "Invalid state"
        );

        companies[id].status = uint256(WorkflowState.Registered);

        emit ActionChanged(getMethodSig(msg.data));

        return true;
    }

    //    function setMaintainer(
    //         address caller,
    //         bytes memory params
    //     ) public  returns(bool) {
    //         (uint id) =
    //         abi.decode(
    //             params,
    //             (uint)
    //         );

    //         require(companies[id].status == uint(WorkflowState.NotaryStamped), "Invalid state");

    //         companies[id].status = uint(WorkflowState.Registered);

    //         emit ActionChanged(
    //             getMethodSig(msg.data),
    //             params
    //         );

    //         return true;
    //     }
}
