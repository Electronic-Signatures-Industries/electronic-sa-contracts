pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./WFlowRegistry.sol";
import "./MinLibBytes.sol";

contract TestActionSAContract is WMessages {


    struct SociedadAnonima {
        string name;
        string companyAddress;
        string industry;
        bool verifiedName;
        string ruc;
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
    function createSA(
        address caller,
        bytes memory params
    ) public returns(uint) {
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
            verifiedName: false
        });

        emit CompanyAdded(name, counter);

        return counter;
    }

    function hasValidName(
        address caller,
        bytes memory params
    ) 
    public view returns(bool) {
        uint id = abi.decode(params, (uint));
        return companies[id].verifiedName;
    }


    function setValidName(
        uint id,
        bool ok
    ) 
    public returns(bool) {
        companies[id].verifiedName = ok;
        return true;
    }

    // Register SA
    function registerSA(
        address caller,
        bytes memory params
    ) public returns(bool) {
        (uint id,
         string memory ruc) =
        abi.decode(
            params,
            (uint, string) 
        );

        companies[id].ruc = ruc;

        emit CompanyRegistered(companies[id].name, ruc, id);

        return true;
    }

    // Add Partner

    // Issue Stocks

    // Request Operations Start

}