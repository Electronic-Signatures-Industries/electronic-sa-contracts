pragma solidity ^0.7.0;

import "./WFlowRegistry.sol";

/**
 *  Manages message state flows
 */
contract WStateRelayer is WFlowRegistry {
  
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    /** NatDoc
     * @dev Send payload message to be process by a WAction smart contract
     * minter
     * selfMint
     * tokenURI
     */
    function executeMessage(
        bytes32 topicKey,
        WorkflowPayload payload
    ) public returns (bool) {

        require(topicRoutes[topicKey] != address(0), "Missing topic key");
        WAction(topicRoutes[topicKey],topicAddress).run(
            topic,
            payload
        );

        return true;
    }
}
