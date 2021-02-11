pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./WFlowRegistry.sol";
import "./MinLibBytes.sol";
import "./WMessages.sol";

contract TestActionSAContract is WMessages {

 
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
        uint status;
        // Has been verified
        bool verifiedRuc;
        uint memberCount;
    }

    struct Member {
        string did;
        address member;
    }

    mapping (uint => mapping( uint => Member)) public members;

    enum WorkflowState {
        SearchName,
        AddMembers,
        RegisterCompany, // Name, Members, Capital, 
        NotaryStamped,
        Registered,
        OperationsRequested,
        OperationsNoticeCompleted
    }

    event CompanyAdded(
        string name,
        uint indexed id
    );

    event MemberAdded(
        string memberDID,
        address member,
        uint companyId,
        uint indexed id
    );

    event CompanyRegistered(
        string name,
        string ruc,
        uint indexed  id
    );

    uint public counter;
    mapping(uint => SociedadAnonima) public companies;
    mapping(address => mapping(string => bool)) public userWhitelist; 

    address public owner;
    constructor(address _owner) {
        owner = _owner;
    }

    /* Async Message Flow Functions */

    /* Property Getters and Setters */
    // Has Valid Name verifies company name has been completed
    function hasValidName(
        address caller,
        bytes calldata params
    ) 
    external  returns(bool) {
        uint id = abi.decode(params, (uint));
        return true;
    }


    // Sets a valid name
    function setValidName(
        uint id,
        bool ok
    ) 
    public returns(bool) {
        require(userWhitelist[msg.sender]["setValidName"], "Invalid sender");
        require(companies[id].verifiedName == false, "Name already verified");
        companies[id].verifiedName = ok;
        bytes memory params = abi.encodePacked(ok);
        emit PropertyChanged("verifiedName", params);
        return true;
    }


    function setRUC(
        uint id,
        string memory ruc
    ) 
    public returns(bool) {
        require(userWhitelist[msg.sender]["setValidName"], "Invalid sender");
        require(companies[id].verifiedRuc == false, "RUC already verified");
        companies[id].ruc = ruc;
        companies[id].verifiedRuc = true;
        bytes memory params = abi.encodePacked(ruc);
        emit PropertyChanged("ruc", params);
        return true;
    }

    function hasRUC(
        address caller,
        bytes calldata params
    ) 
    external  returns(bool) {
        uint id = abi.decode(params, (uint));
        return companies[id].verifiedRuc;
    }

    function setStatus(
        uint id,
        uint status
    ) 
    public returns(bool) {
        require(userWhitelist[msg.sender]["setStatus"], "Invalid sender");
        companies[id].status = status;
        bytes memory params = abi.encodePacked(status);
        emit PropertyChanged("status", params);
        return true;
    }

    function hasStatus(
        address caller,
        bytes calldata params
    ) 
    external  returns(bool) {
        uint id = abi.decode(params, (uint));
        return companies[id].status == id;
    }

    // Create SA
    function propose(
        address caller,
        bytes memory params
    ) public returns(uint) {
        (string memory name,
         string memory metadataURI) =
        abi.decode(
            params,
            (string, string) 
        );

        companies[counter] = SociedadAnonima({
            name: name,
            ruc: "",
            verifiedName: false,
            verifiedRuc: false,
            status: uint(WorkflowState.SearchName),
            legalResidentAgent: address(0),
            legalResidentAgentDID: "",
            metadataURI: metadataURI,
            memberCount: 0
        });
        counter++;

        emit ActionChanged(
            getMethodSig(msg.data), 
            params
        );
        emit CompanyAdded(
            name,
            counter
        );

        return counter;
    }


    function addMemberKYC(
        address caller,
        bytes memory params
    ) public returns(uint) {
        require(userWhitelist[msg.sender]["addMemberKYC"], "Invalid sender");

        (uint id,
        address member,
         string memory did) =
        abi.decode(
            params,
            (uint, address, string) 
        );

        uint memberId = companies[id].memberCount;
        members[id][memberId] = Member({
            did: did,
            member: member
        });

        companies[id].memberCount = companies[id].memberCount + 1;

        emit ActionChanged(
            getMethodSig(msg.data), 
            params
        );
        
        emit MemberAdded(
            did,
            member,
            id,
            memberId
        );

        return memberId;

    }


    // Register SA
    function register(
        address caller,
        bytes memory params
    ) public returns(bool) {
        require(userWhitelist[msg.sender]["register"], "Invalid sender");
        
        (uint id,
        string memory metadataURI,
        address legalResidentAgent,
         string memory legalResidentAgentDID) =
        abi.decode(
            params,
            (uint, string, address, string) 
        );


        companies[id].legalResidentAgent = legalResidentAgent;
        companies[id].legalResidentAgentDID = legalResidentAgentDID;
        companies[id].metadataURI = metadataURI;
        companies[id].status = uint(WorkflowState.RegisterCompany);

        emit ActionChanged(
            getMethodSig(msg.data), 
            params
        );

        return true;
    }

    function notaryStamp(
        address caller,
        bytes memory params
    ) public returns(bool) {
        require(userWhitelist[msg.sender]["notaryStamp"], "Invalid sender");

        (uint id) =
        abi.decode(
            params,
            (uint) 
        );

        companies[id].status = uint(WorkflowState.NotaryStamped);

        emit ActionChanged(
            getMethodSig(msg.data), 
            params
        );

        return true;
    }

    function companyRegisterd(
        address caller,
        bytes memory params
    ) public returns(bool) {
        require(userWhitelist[msg.sender]["addMemberKYC"], "Invalid sender");
 
        (uint id) =
        abi.decode(
            params,
            (uint) 
        );

        companies[id].status = uint(WorkflowState.Registered);

        emit ActionChanged(
            getMethodSig(msg.data), 
            params
        );

        return true;
    }

}