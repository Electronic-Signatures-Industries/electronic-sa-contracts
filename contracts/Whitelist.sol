pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./Utils.sol";

contract Whitelist is Utils {

    address private owner;

    event UserWhitelistChanged(
        address caller,
        bytes4 methodName,
        bool enable
    );

    mapping (address => mapping( bytes4 => bool)) public actionWhitelisting;

    mapping(address => mapping(bytes4 => bool)) public userWhitelist; 

    modifier onlyWhitelisted(address sender, bytes4 data) {
        require(userWhitelist[sender][data] == true, "Invalid sender");
        _;
    }

    constructor(address _owner)  {
        owner = _owner;
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