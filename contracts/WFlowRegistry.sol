pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ERC20Interface.sol";
import "./WMessages.sol";

/**
 * Maintains workflow state machine flow
 */
contract WFlowRegistry  is WMessages {
    address public owner;
    ERC20Interface public stablecoin;
    uint public fee;
    mapping (address => mapping( bytes4 => ActionRoute)) public actions;
    mapping (address => uint) public accounting;

    event Withdrawn(address indexed payee, uint256 weiAmount);

    
    event MessageEntryAdded(
        address from,
        address actionAddress,
        bytes32 id
    );

    function getAction(
        address controller,
        bytes4 selector
    ) public view returns(ActionRoute memory) {
        return actions[controller][selector];
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

    function mapMessageToController(
        address controller,
        bytes4 messageRequest,
        bytes4[] memory conditions,
        bool[] memory conditionStatus,
        bytes4 nextMessage
    )
        external
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

        require(
            conditions.length == conditionStatus.length,
            "Invalid conditions size"
        );

        /* require(
            stablecoin.balanceOf(msg.sender) == (mintingServiceFee.sum(protocolServiceFee)), 
            "MUST SEND FEE BEFORE USE");
        */

        require(actions[controller][messageRequest].controller == address(0), "Address already exists");

        // register topic and mutation
        actions[controller][messageRequest] = ActionRoute({
            selector: messageRequest,
            nextSelector: nextMessage,
            controller: controller,
            conditions: conditions,
            conditionStatus: conditionStatus
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
        accounting[msg.sender] = accounting[msg.sender] + fee;
        accounting[address(this)] = accounting[address(this)] + fee;
        emit MessageEntryAdded(
            msg.sender,
            controller,
            messageRequest
        );

        return true;
    }       


}