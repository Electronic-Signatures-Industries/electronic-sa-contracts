pragma solidity ^0.7.0;

import "./WFlowRegistry.sol";
import "./MinLibBytes.sol";

/**
 *  Manages message state flows
 */
contract WStateRelayer is WFlowRegistry {

    constructor() public {
    }


    event MessageMutationRelayed(
        bytes4 mutation,
        address mutationAddress,
        bytes payload
    );

    /** NatDoc
     * @dev Send payload message to be process by a WAction smart contract
     * minter
     * selfMint
     * tokenURI
     */
    function executeMessage(
        bytes4 selector,
        WorkflowPayload memory payload
    ) public returns (bool) {

        // check if it has been whitelisted and purchased
        require(topicRoutes[selector].topicAddress != address(0), "Missing topic key");
        address target = topicRoutes[selector].topicAddress;
        (bool success, bytes memory ret) =  target.call(
            abi.encodeWithSelector(
                topicRoutes[selector].topic,
                payload,
                msg.sender)
        );
           
        if ( success && mutationRoutes[selector].mutationAddress != address(0)) {
            address next = mutationRoutes[selector].mutationAddress;
            (bool ok, bytes memory res) =  target.call(
            abi.encodeWithSelector(
                mutationRoutes[selector].mutation,
                ret,
                msg.sender)
            );
        }
        return true;
    }
}
