pragma solidity ^0.7.0;
import "./ERC20Interface.sol";


/**
 * Maintains workflow state machine flow
 */
contract WFlowRegistry  {
 
 


    address public owner;
    ERC20Interface public stablecoin;
    uint public fee;
    mapping (bytes32 => TopicRoute) public topicRoutes;
    mapping (bytes32 => MutationRoute) public mutationRoutes;
    event Withdrawn(address indexed payee, uint256 weiAmount);


    struct TopicRoute {
        bytes4 topic;
        address topicAddress;
    }

    struct MutationRoute {
        bytes4 mutation;
        address mutationAddress;
    }

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

    event WorkflowEntryAdded(
        address from,
        address topicAddress,
        bytes32 id
    );

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
        bytes4 topicSelector,
        address topicAddress,
        bytes4 mutationSelector,
        address mutationAddress,
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
        bytes32 topicUid = keccak256(
            abi.encodePacked(
                topicSelector,
                topicAddress
                )
            );
        bytes32 mutationUid = keccak256(
            abi.encodePacked(
                mutationSelector,
                mutationAddress
                )
            );

        require(topicRoutes[topicSelector].topicAddress != address(0),
        "Topic and address already exists");

        // register topic and mutation
        topicRoutes[topicSelector] = TopicRoute({
            topic: topicSelector,
            topicAddress: topicAddress
        });


        require(mutationRoutes[topicSelector].mutationAddress != address(0),
        "Mutation and address already exists");

        // register topic and mutation
        mutationRoutes[topicSelector] = MutationRoute({
            mutation: mutationSelector,
            mutationAddress: mutationAddress
        });

        // TODO: Update accounting
        //  - create mappings to data provider accounting
        //  - create mappings to protocol fee accounting
        // Transfer tokens to pay service fee
        require(
            stablecoin.transferFrom(
                msg.sender,
                address(this), 
                fee,
            "Transfer failed for fee"
        ));

        emit WorkflowEntryAdded(
            msg.sender,
            topicAddress,
            topicUid
        );

        return true;
    }       


}