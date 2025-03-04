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

    function revertWithData(bytes memory data) internal pure {
        assembly {
            revert(add(data,32), mload(data))
        }
    }

    /**
     * @dev execute conditions
     * @param controller contract address
     * @param selector function name
     * @param jobId job id
     */
    function executeActionConditions(
        address controller,
        bytes4 selector,
        uint jobId
    ) public returns (bool) {

        // check if it has been whitelisted and purchased
        require(registry.getAction(controller, selector).conditions.length > 0, "Missing action key");
        require(
            relayJob.hasInit(jobId), "Job already completed"
        );
        ActionRoute memory item = registry.getAction(controller, selector);    
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
                    relayJob.get(jobId).response
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
            relayJob.get(jobId).status = 2;
            emit MessageRequestCompleted(
                item.controller,
                item.selector,
                jobId
            );
        }

        return true;
    }
}
