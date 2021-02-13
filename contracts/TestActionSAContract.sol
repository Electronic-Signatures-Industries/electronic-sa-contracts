pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./MinLibBytes.sol";
import "./MessageRoute.sol";


import "./Maintainer.sol";

contract TestActionSAContract is StateRelayer {

 
    Maintainer private maintainer;
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

    mapping (uint => mapping(uint => Member)) public members;

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

    event RequestBoardMembersKYC(
        uint indexed id
    );

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

    constructor(address _owner, address _maintainer) {
        maintainer = _maintainer;
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
        return companies[id].verifiedName;
    }


    // Sets a valid name
    function setValidName(
        uint id,
        bool ok
    ) 
    public
    propertyChange("verifiedName", abi.encodePacked(ok))
     returns(bool) {
        require(companies[id].verifiedName == false, "Name already verified");
        companies[id].verifiedName = ok;
        return true;
    }


    function setRUC(
        uint id,
        string memory ruc
    ) 
    public
    propertyChange("ruc", abi.encodePacked(ruc))
    returns(bool) {
        require(companies[id].verifiedRuc == false, "RUC already verified");
        companies[id].ruc = ruc;
        companies[id].verifiedRuc = true;
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

    function hasMemberKYCCompleted(
        address caller,
        bytes calldata params
    ) 
    external  returns(bool) {
        uint id = abi.decode(params, (uint));
        return companies[id].status == uint(WorkflowState.KYCCompleted);
    }

    function hasRegistered(
        address caller,
        bytes calldata params
    ) 
    external  returns(bool) {
        uint id = abi.decode(params, (uint));
        return companies[id].status == uint(WorkflowState.Registered);
    }


    function hasNotarized(
        address caller,
        bytes calldata params
    ) 
    external  returns(bool) {
        uint id = abi.decode(params, (uint));
        return companies[id].status == uint(WorkflowState.NotaryStamped);
    }

    function setStatus(
        uint id,
        uint status
    ) 
    public
    propertyChange("status", abi.encodePacked(status))
    returns(bool) {
        companies[id].status = status;
        bytes memory params = abi.encodePacked(status);
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
        address agent,
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
            legalResidentAgent: agent,
            legalResidentAgentDID: "",
            metadataURI: metadataURI,
            memberCount: 0
        });
        counter++;

        uint jobCounter = relayJob.addJob(abi.encodePacked(counter), selector);
        
        emit MessageRelayed(
            jobCounter
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
    ) public
      onlyWhitelisted
     returns(uint) {

        (uint id,
        address member,
         string memory did) =
        abi.decode(
            params,
            (uint, address, string) 
        );

        require(companies[id].status == uint(WorkflowState.RequestKYC), "Invalid state");

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

    // Client must call setStatus once he enrolls 3 KYC Profiles


    // Register SA
    function register(
        address caller,
        bytes memory params
    ) public onlyWhitelisted returns(bool) {
        (uint id,
        string memory metadataURI,
        address legalResidentAgent,
         string memory legalResidentAgentDID) =
        abi.decode(
            params,
            (uint, string, address, string) 
        );

        require(companies[id].status == uint(WorkflowState.AddMembers), "Invalid state");

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
    ) public onlyWhitelisted returns(bool) {
        (uint id) =
        abi.decode(
            params,
            (uint) 
        );
        require(companies[id].status == uint(WorkflowState.RegisterCompany), "Invalid state");

        companies[id].status = uint(WorkflowState.NotaryStamped);

        emit ActionChanged(
            getMethodSig(msg.data), 
            params
        );

        return true;
    }


    function requestKYC(
        address caller,
        bytes memory params
    ) public onlyWhitelisted returns(bool) {
        (uint id) =
        abi.decode(
            params,
            (uint) 
        );
        companies[id].status = uint(WorkflowState.RequestKYC);

        emit ActionChanged(
            getMethodSig(msg.data), 
            params
        );

        emit RequestBoardMembersKYC(id);

        return true;
    }

    function completeCompanyRegistration(
        address caller,
        bytes memory params
    ) public onlyWhitelisted returns(bool) {
        (uint id) =
        abi.decode(
            params,
            (uint) 
        );

        require(companies[id].status == uint(WorkflowState.NotaryStamped), "Invalid state");

        companies[id].status = uint(WorkflowState.Registered);

        emit ActionChanged(
            getMethodSig(msg.data), 
            params
        );

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