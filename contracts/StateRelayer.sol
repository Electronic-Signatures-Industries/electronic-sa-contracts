pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ActionRouteRegistry.sol";
import "./MinLibBytes.sol";

/**
 *  Manages message state flows
 */
contract StateRelayer  is MessageRoute {
    ActionRouteRegistry public registry;
    mapping(address => uint256) public nonces;
    constructor(address wfRegistry) public {
        registry = ActionRouteRegistry(wfRegistry);
    }

    uint public jobCounter;
    mapping (uint => MessageRequest) public jobs;

    struct MessageRequest {
        uint status;
        uint id;
        bytes request;
        bytes response;
        bytes4 selector;
    }

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



    function getNonce(address user) external view returns(uint256 nonce) {
        nonce = nonces[user];
    
    }
    /** NatDoc
     * @dev Send payload message to be process by a WAction smart contract
     * minter
     * selfMint
     * tokenURI
     */
    function executeAction(
        bytes32 domainSeparator,
        bytes4 selector,
        bytes memory params
    ) public returns (uint) {

        // check if it has been whitelisted and purchased
        require(registry.getAction(domainSeparator, selector).controller != address(0), "Missing topic key");
        
        (bool success, bytes memory ret) =  registry
        .getAction(domainSeparator, selector).controller
        .call(
            abi.encodeWithSelector(
                registry.getAction(domainSeparator, selector).selector,
                msg.sender,
                params
                )
        );
        if (!success){
          //re-throw the revert with the same revert reason.
          revertWithData(ret);
          return 0;
        }
        jobCounter++;
        jobs[jobCounter] = MessageRequest({
            status: 0,
            id: jobCounter,
            request: params,
            response: ret,
            selector: selector
        });
        
        emit MessageRelayed(
            params, 
            ret,
            jobCounter
        );

        return jobCounter;
    }

    function revertWithData(bytes memory data) internal pure {
        assembly {
            revert(add(data,32), mload(data))
        }
    }

    // Solo puede ser getter
    // El switch de MessageConditionFound, llama al siguiente paso
    function executeActionConditions(
        bytes32 domainSeparator,
        bytes4 selector,
        uint jobId
    ) public returns (bool) {

        // check if it has been whitelisted and purchased
        require(registry.getAction(domainSeparator, selector).conditions.length > 0, "Missing topic key");
        require(
            jobs[jobId].status  == 0, "Job already completed"
        );
        ActionRoute memory item = registry.getAction(domainSeparator, selector);    
        // check if it has been whitelisted and purchased
        require(item.controller != address(0), "Missing topic key");

        bool conditionsCompleted = true;
        for (uint i = 0;i<item.conditions.length;i++) {
            (bool ok, bytes memory res) =  item
            .controller
            .call(
                abi.encodeWithSelector(
                    item.conditions[i],
                    msg.sender,
                    jobs[jobId].response
                )
            );
        if (!ok){
          //re-throw the revert with the same revert reason.
          revertWithData(res);
          return true;
        }

            (bool conditionResult) = abi.decode(res, (bool));
            item.conditionStatus[i] = conditionResult;

            conditionsCompleted = conditionsCompleted && conditionResult;
        }

        if (conditionsCompleted == true) {
            jobs[jobId].status = 1;
            emit MessageRequestCompleted(
                item.controller,
                item.selector,
                jobId
            );
        }

        return true;
    }
}
