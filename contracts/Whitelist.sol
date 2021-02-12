pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Utils.sol";

contract Whitelist is Utils {

    address public owner;

    event UserWhitelistChanged(
        address caller,
        bytes4 methodName,
        bool enable
    );

    mapping (bytes32 => mapping( bytes4 => bool)) public actionWhitelisting;

    mapping(address => mapping(bytes4 => bool)) public userWhitelist; 

    modifier onlyWhitelisted {
        require(userWhitelist[msg.sender][getMethodSig(msg.data)], "Invalid sender");
        _;
    }

    function setUserWhitelist(
        address caller,
        bytes4 fnName,
        bool enable
    ) public returns(bool) {
        require(owner == msg.sender, "Not authorized");

        userWhitelist[caller][fnName] = enable;

        emit UserWhitelistChanged(
            caller,
            fnName,
            enable
        );
    }

}