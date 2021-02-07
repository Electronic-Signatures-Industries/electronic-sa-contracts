pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ERC20Interface.sol";

contract WMessages {
// A Workflow payload can either be content addressable document or NFT address with supplied token id
    struct WorkflowPayload  {
        // IPLD has containing document
        string documentURI;
        // Agent DID
        string didAgent;
        // Owner address
        address payloadOwner;
        // Owner DID
        string didPayloadOwner;
        // timeout message if router can't find addresss
        uint timeoutAfterRetries;
        // NFT Address if ERC721
        address nftAddress;
        // NFT TokenID
        uint tokenId;
    }
}
/**
 * Maintains workflow state machine flow
 */
contract WFlowRegistry  is WMessages {
    address public owner;
    ERC20Interface public stablecoin;
    uint public fee;
    mapping (bytes4 => ActionRoute) public actions;
    mapping (bytes4 => NextRoute) public nextActions;
    event Withdrawn(address indexed payee, uint256 weiAmount);


    struct ActionRoute {
        bytes4 topic;
        address actionAddress;
    }

    struct NextRoute {
        bytes4 mutation;
        address nextAddress;
    }

    
    event WorkflowEntryAdded(
        address from,
        address actionAddress,
        bytes32 id
    );

    function getAction(
        bytes4 selector
    ) public view returns(ActionRoute memory) {
        return actions[selector];
    }

    function getNext(
        bytes4 selector
    ) public view returns(NextRoute memory) {
        return nextActions[selector];
    }    

    /**
    * XDV Data Token
    */
    constructor(
        address tokenAddress
    ) public  {
        owner = msg.sender;
        stablecoin  = ERC20Interface(tokenAddress);
    }
   
    function setProtocolConfig(uint256 _fee) public {
        require(msg.sender == owner, "INVALID_USER");
        fee = _fee;
    }

    function getProtocolConfig() public returns (uint256) {
        return (fee);
    }

    function withdraw(address payable payee) public {
        require(msg.sender == owner, "INVALID_USER");
        uint256 b = address(this).balance;
        payee.transfer(address(this).balance);

        emit Withdrawn(payee, b);
    }

    function withdrawToken(address payable payee, address token) public {
        require(msg.sender == owner, "INVALID_USER");
        uint256 b = ERC20Interface(token).balanceOf(address(this));
        payee.transfer(b);

        emit Withdrawn(payee, b);
    }

    // topic ABI Function Ethers
    // ExecutePrescription(uint, uint, string) === bytes32
    // 0xA1...

    function registerWorkflowEntry(
        bytes4 actionSelector,
        address actionAddress,
        bytes4 nextSelector,
        address nextAddress,
        WorkflowPayload memory payload
    )
        public
        payable
        returns (bool)
    {

        // User must have a balance
        require(
            stablecoin.balanceOf(msg.sender) >= 0,
            "Invalid token balance"
        );
        // User must have an allowance
        require(
            stablecoin.allowance(msg.sender, address(this)) >= 0,
            "Invalid token allowance"
        );

        /* require(
            stablecoin.balanceOf(msg.sender) == (mintingServiceFee.sum(protocolServiceFee)), 
            "MUST SEND FEE BEFORE USE");
        */

        require(actions[actionSelector].actionAddress != address(0),
        "Topic and address already exists");

        // register topic and mutation
        actions[actionSelector] = ActionRoute({
            topic: actionSelector,
            actionAddress: actionAddress
        });


        require(nextActions[actionSelector].nextAddress != address(0),
        "Mutation and address already exists");

        // register topic and mutation
        nextActions[actionSelector] = NextRoute({
            mutation: nextSelector,
            nextAddress: nextAddress
        });

        // TODO: Update accounting
        //  - create mappings to data provider accounting
        //  - create mappings to protocol fee accounting
        // Transfer tokens to pay service fee
        require(
            stablecoin.transferFrom(
                msg.sender,
                address(this), 
                fee),
            "Transfer failed for fee"
        );

        emit WorkflowEntryAdded(
            msg.sender,
            actionAddress,
            actionSelector
        );

        return true;
    }       


}