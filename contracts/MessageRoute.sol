pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract MessageRoute {

    event PropertyChanged(string propName, bytes data);
    event ActionChanged(bytes4 methodSig, bytes request);
    
    struct ActionRoute {
        bytes4 selector;
        address controller;
        bytes4[] conditions;
        bool[] conditionStatus;
    }
    
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        )
    );



    event MessageRelayed(
        bytes request,
        bytes response,
        uint id
    );


    event MessageRequestCompleted(
        address controller,
        bytes4 selector,
        uint id
    );

    modifier propertyChange(string memory field, bytes memory params) {
        _;
        emit PropertyChanged(field, params);
    }
    function getDomainSeparator(
        string memory contractName,
        address contractAddress,
        uint network,
        string memory version
                
        ) external pure returns(bytes32) {
        return keccak256(
        abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(contractName)),
            keccak256(bytes(version)),
            network, 
            address(contractAddress)
        )
    );
    }      
}

