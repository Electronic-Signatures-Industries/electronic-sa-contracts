pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./WFlowRegistry.sol";
import "./WAction.sol";

contract ActionImpl is WFlowRegistry, WAction {
    function run(
        bytes32 topicKey,
        WorkflowPayload payload
    ) public view returns (address) {
        // todo: business logic

        // emit, must be handled by server
        emit ActionCompleted(
            mutation,
            mutationAddress,
            payload
        );
        return address(this);
    }
}
