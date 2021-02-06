pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./WFlowRegistry.sol";


abstract contract WAction is WFlowRegistry {
    function run(
        bytes32 topicKey,
        WorkflowPayload payload
    ) public view returns (address);
}
