pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./WFlowRegistry.sol";
import "./MinLibBytes.sol";
import "./WMessages.sol";

contract TestActionSAContract is WMessages {


    struct SociedadAnonima {
        string name;
        bool verifiedName;        
        string companyAddress;
        string industry;
        string ruc;
        bool verifiedRuc;
    }

    event CompanyAdded(
        string name,
        uint indexed id
    );

    event CompanyRegistered(
        string name,
        string ruc,
        uint indexed  id
    );

    uint public counter;
    mapping(uint => SociedadAnonima) public companies;

    address public owner;
    constructor(address _owner) {
        owner = _owner;
    }

    function isRucReady() 
    public returns(bool) {
        return true;
    }


    // Create SA
    function propose(
        address caller,
        bytes memory params
    ) public returns(bytes memory) {
        (string memory name,
         string memory companyAddress, 
         string memory industry) =
        abi.decode(
            params,
            (string, string, string) 
        );

        counter++;
        // Condition #1: Oracle must verify name is unique
        // Condition #2: RUC somehow autogenerates
        companies[counter] = SociedadAnonima({
            name: name,
            companyAddress: companyAddress,
            industry: industry,
            ruc: "",
            verifiedName: false,
            verifiedRuc: false
        });

        emit ActionChanged(
            getMethodSig(msg.data), 
            params
        );
        emit CompanyAdded(
            name,
            counter
        );

        return abi.encodePacked(
            counter
        );
    }

    function hasValidName(
        address caller,
        bytes calldata params
    ) 
    external  returns(bool) {
        uint id = abi.decode(params, (uint));
        return true;/// abi.encode(companies[id].verifiedName);
    }


    function setValidName(
        uint id,
        bool ok
    ) 
    public returns(bool) {
        companies[id].verifiedName = ok;
        bytes memory params = abi.encodePacked(ok);
        emit PropertyChanged("verifiedName", params);
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


    function setRUC(
        uint id,
        string memory ruc
    ) 
    public returns(bool) {
        require(companies[id].verifiedRuc == false, "RUC already verified");
        companies[id].ruc = ruc;
        companies[id].verifiedRuc = true;
        bytes memory params = abi.encodePacked(ruc);
        emit PropertyChanged("ruc", params);
        return true;
    }

    // Register SA
    function register(
        address caller,
        bytes memory params
    ) public returns(bytes memory) {
        (uint id,
         string memory ruc) =
        abi.decode(
            params,
            (uint, string) 
        );

        // companies[id].ruc = ruc;
        emit ActionChanged(
            getMethodSig(msg.data), 
            params
        );
        emit CompanyRegistered(companies[id].name, ruc, id);

        return abi.encodePacked(true);
    }

    // Add Partner

    // Issue Stocks

    // Request Operations Start

}