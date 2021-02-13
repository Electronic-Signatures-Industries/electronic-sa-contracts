pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ActionRouteRegistry.sol";
import "./MinLibBytes.sol";
import "./RelayJob.sol";

/**
 *  Manages message state flows
 */
contract StateRelayer  is MessageRoute {
    ActionRouteRegistry public registry;
    RelayJob public relayJob;

    constructor(
        address wfRegistry,
        address relayJobService
    ) public {
        relayJob = RelayJob(relayJobService);
        registry = ActionRouteRegistry(wfRegistry);
    }

    modifier registerState(
        bytes32 domainSeparator,
        bytes4 selector
    ) {

        // check if it has been whitelisted and purchased
        require(registry.getAction(domainSeparator, selector).controller != address(0), "Missing topic key");
        _;       
 
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
        uint jobCounter = relayJob.addJob(params, ret, selector);
        
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
        require(registry.getAction(domainSeparator, selector).conditions.length > 0, "Missing action key");
        require(
            relayJob.hasInit(jobId), "Job already completed"
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
                    relayJob.jobs(jobId).response
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
            relayJob.jobs(jobId).status = 1;
            emit MessageRequestCompleted(
                item.controller,
                item.selector,
                jobId
            );
        }

        return true;
    }
}
