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

    uint public jobCounter;
    mapping (uint => MessageRequest) public jobs;

    struct MessageRequest {
        uint status;
        uint id;
        bytes request;
        bytes response;
        bytes4 selector;
        bytes4 next;
    }

    event MessageRelayed(
        bytes request,
        bytes response,
        uint id
    );


    event MessageRequestCompleted(
        address controller,
        bytes4 selector,
        bytes4 next,
        uint id
    );
    /** NatDoc
     * @dev Send payload message to be process by a WAction smart contract
     * minter
     * selfMint
     * tokenURI
     */
    function executeRequestResponse(
        bytes4 selector,
        bytes memory params
    ) public returns (uint) {

        // check if it has been whitelisted and purchased
        require(registry.getAction(selector).controller != address(0), "Missing topic key");
        
        (bool success, bytes memory ret) =  registry
        .getAction(selector).controller
        .call(
            abi.encodeWithSelector(
                registry.getAction(selector).selector,
                msg.sender,
                params
                )
        );

        jobCounter++;
        jobs[jobCounter] = MessageRequest({
            status: 0,
            id: jobCounter,
            request: params,
            response: ret,
            selector: selector,
            next: registry.getAction(selector).nextSelector
        });
        
        emit MessageRelayed(
            params, 
            ret,
            jobCounter
        );

        return jobCounter;
    }

    // Solo puede ser getter
    // El switch de MessageConditionFound, llama al siguiente paso
    function executeJobCondition(
        bytes4 selector,
        uint jobId
    ) public returns (bool) {

        // check if it has been whitelisted and purchased
        require(registry.getAction(selector).conditions.length > 0, "Missing topic key");
        require(
            jobs[jobId].status  == 0, "Job already completed"
        );
        bool conditionsCompleted = false;
        for (uint i = 0;i<registry.getAction(selector).conditions.length;i++) {
            (bool ok, bytes memory res) =  registry
            .getAction(selector)
            .controller
            .call(
            abi.encodeWithSelector(
                registry.getAction(selector).conditions[i],
                msg.sender,
                jobs[jobId].response
            )
            );

            (bool conditionResult) = abi.decode(res, (bool));
            registry.getAction(selector).conditionStatus[i] = conditionResult;

            conditionsCompleted = conditionsCompleted && conditionResult;
        }

        if (conditionsCompleted) {
            jobs[jobId].status = 1;
            emit MessageRequestCompleted(
                registry.getAction(selector).controller,
                registry.getAction(selector).selector,
                registry.getAction(selector).nextSelector,
                jobId
            );
        }

        return true;
    }
}
