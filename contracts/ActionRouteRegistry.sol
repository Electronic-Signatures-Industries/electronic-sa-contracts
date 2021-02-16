pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ERC20Interface.sol";
import "./MessageRoute.sol";
import "./Whitelist.sol";

/**
 * @dev Registers and stores contracts decorated with mapAction
 * Makes contract functions to have conditions that can be executed by bots
 * Uses Whitelist and MessageRoute mixins
 */
contract ActionRouteRegistry is Whitelist, MessageRoute {
    // Stable coin
    ERC20Interface public stablecoin;

    // Fee
    uint public fee;

    // Registered actions
    mapping (address => mapping( bytes4 => ActionRoute)) public actions;
    
    // Accounting
    mapping (address => uint) public accounting;

    // Events
    event Withdrawn(address indexed payee, uint256 weiAmount);
    
    event MessageEntryAdded(
        address from,
        address controller,
        bytes32 id
    );

    /* Reads an action
    */
    function getAction(
        address controller,
        bytes4 selector
    ) public view returns(ActionRoute memory) {
        return actions[controller][selector];
    }

    address  private owner;

    /**
    * constructor
    */
    constructor(
        address tokenAddress
    ) public Whitelist(msg.sender)  {
        owner = msg.sender;
        stablecoin  = ERC20Interface(tokenAddress);
    }
   
    // Sets protocol fee
    function setProtocolFee(uint256 _fee) public {
        require(msg.sender == owner, "INVALID_USER");
        fee = _fee;
    }

    // Gets protocol fee
    function getProtocolFee() public view returns (uint256) {
        return (fee);
    }

    // Withdraw funds
    function withdraw(address payable payee) public {
        require(msg.sender == owner, "INVALID_USER");
        uint256 b = address(this).balance;
        payee.transfer(address(this).balance);

        emit Withdrawn(payee, b);
    }

    // Withdraw ERC-20
    function withdrawToken(address payable payee, address token) public {
        require(msg.sender == owner, "INVALID_USER");
        uint256 b = ERC20Interface(token).balanceOf(address(this));
        payee.transfer(b);

        emit Withdrawn(payee, b);
    }


    //  Maps an action that can be query for conditions
    function mapAction(
        address controller,
        bytes4 messageRequest,
        bytes4[] memory conditions,
        bool[] memory conditionStatus
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

        require(
            conditions.length < 6,
            "Max 5 conditions"
        );
        /* require(
            stablecoin.balanceOf(msg.sender) == (mintingServiceFee.sum(protocolServiceFee)), 
            "MUST SEND FEE BEFORE USE");
        */

        require(actions[controller][messageRequest].controller == address(0), "Address already exists");

        // register topic and mutation
        actions[controller][messageRequest] = ActionRoute({
            selector: messageRequest,
            controller: controller,
            conditions: conditions,
            conditionStatus: conditionStatus
        });

        

        // Update accounting
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
        actionWhitelisting[controller][messageRequest] = true;


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