pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


contract TestMutationSAContract {

    struct SociedadAnonima {
        string name;
        string companyAddress;
        string industry;
    }

    mapping(bytes32 => SociedadAnonima) public companies;

    address public owner;
    constructor(address _owner) {
        owner = _owner;
    }

    function isRucReady() 
    public returns(bool) {
        return true;
    }


    // Request Partner KYC

    // 1) True: Stores KYC / Create DID

    // 2) Emit failure

    // Register issues stocks / mint something

    // Sends operations start using messaging, push or something else
    

}