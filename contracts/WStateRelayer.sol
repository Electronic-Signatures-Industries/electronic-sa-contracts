pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./WFlowRegistry.sol";
import "./MinLibBytes.sol";

/**
 *  Manages message state flows
 */
contract WStateRelayer  is WMessages {
    WFlowRegistry public registry;
    constructor(address wfRegistry) public {
        registry = WFlowRegistry(wfRegistry);
    }


    event MessagRelayed(
        bytes4 mutation,
        address mutationAddress,
        WorkflowPayload payload
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
        require(registry.getAction(selector).actionAddress != address(0), "Missing topic key");
        address target = registry.getAction(selector).actionAddress;
        (bool success, bytes memory ret) =  target.call(
            abi.encodeWithSelector(
                registry.getAction(selector).topic,
                payload.didAgent,
                payload.didPayloadOwner,
                payload.documentURI,
                payload.nftAddress,
                payload.tokenId,
                payload.payloadOwner,
                msg.sender)
        );
           
        if ( success && (registry.getNext(selector).nextAddress != address(0))) {
            address next = registry.getNext(selector).nextAddress;
            (bool ok, bytes memory res) =  target.call(
            abi.encodeWithSelector(
                registry.getNext(selector).mutation,
                ret,
                msg.sender)
            );

            emit MessagRelayed(
                registry.getNext(selector).mutation, 
                registry.getNext(selector).nextAddress,
                payload);
        }
        return true;
    }
}
